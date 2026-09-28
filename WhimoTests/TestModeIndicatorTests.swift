//
//  TestModeIndicatorTests.swift
//  Whimo
//
//  Created on 15.09.2026.
//
//  Copyright (c) 2026 EFI https://efi.int/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
import Combine
import SwiftUI
import FactoryKit
import FlowStacks
import CommonUI
import Resources
import StorageKit
@testable import Whimo

@MainActor
final class TestModeIndicatorTests: XCTestCase {
    func testRememberedModeFollowsApplicationNavigationAndExcludesModalAncestry() async {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "indicator-" + UUID().uuidString))
        defer { defaults.clear() }
        let repository = BusinessModeRepositoryImpl(store: defaults, environment: "debug")
        repository.select(.test)
        let reopened = BusinessModeRepositoryImpl(store: defaults, environment: "debug")
        let transition = BusinessModeInteractorImpl(repository: reopened, cleaner: PreloadUnusedCleaner(), appState: state)
        AppContainer.shared.businessModeInteractor.register { transition }.scope(.unique)
        AppContainer.shared.appState.register { state }.scope(.unique)
        let model = RootTestModeViewModel()
        XCTAssertEqual(model.visibleRouteIndices, [])
        let paths: [(Routes<Screen>, Set<Int>)] = [
            ([.root(.tabBar)], [0]),
            ([.root(.tabBar), .push(.transactionDetails(transactionId: "fixture"))], [0, 1]),
            ([.root(.tabBar), .push(.createTransaction), .push(.scanQR)], [0, 1, 2]),
            ([.root(.tabBar), .push(.addGpsPoint)], [0, 1]),
            ([.root(.tabBar), .push(.changeLanguageFullScreen)], [0, 1]),
            ([.root(.tabBar), .sheet(.more, embedInNavigationView: true), .push(.accountInfo)], [0]),
            ([.root(.tabBar), .cover(.scanQR, embedInNavigationView: true)], [0]),
            ([.root(.tabBar), .push(.documentPicker({ _ in }))], [0]),
            ([.root(.tabBar), .push(.login)], [0]),
            ([.root(.tabBar)], [0]),
            ([.root(.login)], [])
        ]
        for (path, visible) in paths {
            state.navigation[\.path] = path
            let updated = expectation(description: "Root route presentation updated")
            DispatchQueue.main.async { updated.fulfill() }
            await fulfillment(of: [updated], timeout: 3)
            XCTAssertEqual(model.visibleRouteIndices, visible)
        }
    }

    func testSharedChromePlacesBannerAfterNavigationAndFramesOnlyContent() async throws {
        try await assertChromeLayout(inTab: true)
        try await assertChromeLayout(inTab: false)
    }

    private func assertChromeLayout(inTab: Bool) async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        AppContainer.shared.appState.register { state }.scope(.unique)
        state.navigation[\.path] = inTab ? [.root(.tabBar)] : [.root(.tabBar), .push(.accountInfo)]
        let navigator = AppFlowNavigator(.constant(state.navigation.value.path))
        let previousWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        defer { window.isHidden = true; previousWindow?.makeKey() }
        let host = UIHostingController(rootView: AnyView(EmptyView()))
        window.rootViewController = host
        window.makeKeyAndVisible()
        var frames: [CGRect] = []
        for (testMode, offline) in [(false, false), (true, false), (true, true), (false, false)] {
            var measuredView: UIView?
            let laidOut = expectation(description: "Screen content laid out")
            host.rootView = AnyView(IndicatorRouteProbe(inTab: inTab) { view in
                guard measuredView == nil else { return }

                measuredView = view
                laidOut.fulfill()
            }
            .environment(\.showsOfflineBanner, offline)
            .environment(\.showsTestModeIndicator, testMode)
            .environment(\.dynamicTypeSize, .large)
            .environmentObject(navigator)
            .coordinateSpace(name: "screen"))
            host.view.layoutIfNeeded()
            await fulfillment(of: [laidOut], timeout: 3)
            let image = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
                host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
            }
            let contentView = try XCTUnwrap(measuredView)
            let contentFrame = contentView.convert(contentView.bounds, to: host.view)
            frames.append(contentFrame)
            let pixels = try IndicatorPixels(image: image)
            let border = pixels.bounds(red: 144, green: 31, blue: 130)
            let banner = pixels.bounds(red: 240, green: 231, blue: 236)
            if testMode {
                let bannerFrame = try XCTUnwrap(banner)
                let borderFrame = try XCTUnwrap(border)
                XCTAssertEqual(bannerFrame.minY, frames[0].minY, accuracy: 1,
                               "Navigation retains its position above the banner")
                XCTAssertEqual(bannerFrame.maxY + (offline ? 80 : 0), contentFrame.minY, accuracy: 1)
                XCTAssertEqual(borderFrame.minY, contentFrame.minY, accuracy: 1)
                XCTAssertEqual(borderFrame.maxY, contentFrame.maxY, accuracy: 1)
                XCTAssertEqual(borderFrame.width, contentFrame.width, accuracy: 1)
                pixels.assertBorder(around: borderFrame)
            } else {
                XCTAssertNil(border)
                XCTAssertNil(banner)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "chrome-tab-\(inTab)-test-\(testMode)-offline-\(offline)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        XCTAssertGreaterThanOrEqual(frames[1].minY - frames[0].minY, 34)
        XCTAssertEqual(frames[1].maxY, frames[0].maxY, accuracy: 0.5, "Bottom controls retain their region")
        XCTAssertEqual(frames[2].minY - frames[1].minY, 80, accuracy: 0.5, "Offline banner retains its existing region")
        XCTAssertEqual(frames[0], frames[3], "Exit restores ordinary screen space")
    }

    func testChromeWithoutNavigationStartsAtContentTopAndKeepsExactBorderColor() throws {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(AppColors.TestMode.border.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        XCTAssertEqual(red, 144.0 / 255, accuracy: 0.000001)
        XCTAssertEqual(green, 31.0 / 255, accuracy: 0.000001)
        XCTAssertEqual(blue, 130.0 / 255, accuracy: 0.000001)
        XCTAssertEqual(alpha, 1)
        for size in [DynamicTypeSize.large, .accessibility5] {
            let renderer = ImageRenderer(content: Color.white
                .modifier(TestModeScreenModifier(isEnabled: true))
                .environment(\.dynamicTypeSize, size)
                .frame(width: 320, height: 640))
            let pixels = try IndicatorPixels(image: XCTUnwrap(renderer.uiImage))
            let banner = try XCTUnwrap(pixels.bounds(red: 240, green: 231, blue: 236))
            let border = try XCTUnwrap(pixels.bounds(red: 144, green: 31, blue: 130))
            XCTAssertEqual(banner.minY, 0)
            XCTAssertEqual(border.minY, banner.maxY)
            XCTAssertEqual(border.maxY, 640)
            pixels.assertBorder(around: border)
        }
    }

    func testMountedLabelUpdatesWhenSettingsLanguageChanges() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let defaults = AnyStorage(state: UserDefaultsStore(suiteName: "indicator-language-" + UUID().uuidString))
        defer { defaults.clear() }
        AppContainer.shared.userDefaultsStore.register { defaults }.scope(.unique)
        let previousLanguage = UserDefaults.standard.string(forKey: "currentLocalize")
        UserDefaults.standard.set("en", forKey: "currentLocalize")
        defer { UserDefaults.standard.set(previousLanguage, forKey: "currentLocalize") }
        let previousWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        defer { window.isHidden = true; previousWindow?.makeKey() }
        let english = expectation(description: "English indicator laid out")
        let french = expectation(description: "Mounted indicator reflows to full French text")
        var englishHeight: CGFloat?
        var didUpdate = false
        let host = UIHostingController(rootView: TestModeLabel()
            .frame(width: 320)
            .environment(\.dynamicTypeSize, .accessibility5)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                if let englishHeight {
                    if height > englishHeight, !didUpdate {
                        didUpdate = true
                        french.fulfill()
                    }
                } else {
                    englishHeight = height
                    english.fulfill()
                }
            })
        window.rootViewController = host
        window.makeKeyAndVisible()
        await fulfillment(of: [english], timeout: 3)
        ChangeLanguageModule.ViewModel().didTapChange(language: .init(localize: .french))
        await fulfillment(of: [french], timeout: 3)
    }

    func testLabelWrapsAllSupportedLanguagesAtAccessibilitySizes() throws {
        let previousLanguage = UserDefaults.standard.string(forKey: "currentLocalize")
        defer { UserDefaults.standard.set(previousLanguage, forKey: "currentLocalize") }
        for (language, copy) in [
            ("en", "You are in the Test Environment"),
            ("fr", "Vous êtes dans l’environnement de test"),
            ("es", "Estás en el entorno de prueba")
        ] {
            UserDefaults.standard.set(language, forKey: "currentLocalize")
            XCTAssertEqual(AppLocale.TestMode.screenIndicator, copy)
            for width in [320.0, 402.0] {
                var heights: [CGFloat] = []
                for size in [DynamicTypeSize.large, .accessibility5] {
                    let renderer = ImageRenderer(content: TestModeLabel()
                        .environment(\.dynamicTypeSize, size).frame(width: width))
                    let image = try XCTUnwrap(renderer.uiImage)
                    heights.append(image.size.height)
                    XCTAssertEqual(image.size.width, width)
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "indicator-\(language)-\(Int(width))-\(size)"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                }
                XCTAssertGreaterThan(heights[1], heights[0], "The complete label grows instead of truncating")
            }
        }
    }
}

private struct IndicatorRouteProbe: View {
    let inTab: Bool
    let measured: (UIView) -> Void

    var body: some View {
        if inTab {
            VStack(spacing: .zero) {
                TabView { screen }
                Text("Separate tab controls").frame(height: 60)
            }
        } else {
            screen
        }
    }

    private var screen: some View {
        IndicatorLayoutProbe(measured: measured)
            .applyNavigationBar(title: inTab ? "Transactions" : "Account Info", showBackButton: !inTab)
    }
}

private struct IndicatorLayoutProbe: View {
    @Environment(\.showsTestModeIndicator) private var inheritedTestMode
    @Environment(\.showsOfflineBanner) private var inheritedOffline
    let measured: (UIView) -> Void

    var body: some View {
        VStack {
            Color.white
            Button("Bottom action") { }
                .frame(minHeight: 44)
        }
        .background {
            IndicatorGeometryProbe {
                XCTAssertFalse(inheritedTestMode, "Nested navigation must not repeat the Test indicator")
                XCTAssertFalse(inheritedOffline, "Nested navigation must not repeat offline feedback")
                measured($0)
            }
        }
    }
}

/// Measures final hosted content bounds after UIKit completes the render pass.
private struct IndicatorGeometryProbe: UIViewRepresentable {
    let measured: (UIView) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        measured(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) { measured(uiView) }
}

/// Reads the rendered public screen in sRGB, independent of its SwiftUI view structure.
private struct IndicatorPixels {
    let width: Int
    let height: Int
    let scale: CGFloat
    let bytes: [UInt8]

    init(image: UIImage) throws {
        let source = try XCTUnwrap(image.cgImage)
        width = source.width
        height = source.height
        scale = image.scale
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try XCTUnwrap(CGContext(data: &data, width: width, height: height,
                                            bitsPerComponent: 8, bytesPerRow: width * 4,
                                            space: colorSpace,
                                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        bytes = data
    }

    func matches(x: Int, y: Int, red: Int, green: Int, blue: Int) -> Bool {
        guard (0..<width).contains(x), (0..<height).contains(y) else { return false }

        let offset = (y * width + x) * 4
        return abs(Int(bytes[offset]) - red) <= 1 && abs(Int(bytes[offset + 1]) - green) <= 1
            && abs(Int(bytes[offset + 2]) - blue) <= 1
    }

    func bounds(red: Int, green: Int, blue: Int) -> CGRect? {
        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1
        for y in 0..<height {
            for x in 0..<width where matches(x: x, y: y, red: red, green: green, blue: blue) {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
        guard maxX >= 0 else { return nil }

        return CGRect(x: CGFloat(minX) / scale, y: CGFloat(minY) / scale,
                      width: CGFloat(maxX - minX + 1) / scale, height: CGFloat(maxY - minY + 1) / scale)
    }

    func assertBorder(around frame: CGRect, file: StaticString = #filePath, line: UInt = #line) {
        let left = Int((frame.minX + 1) * scale)
        let right = Int((frame.maxX - 1) * scale)
        let top = Int((frame.minY + 1) * scale)
        let bottom = Int((frame.maxY - 1) * scale)
        let horizontal = (left...right).allSatisfy {
            matches(x: $0, y: top, red: 144, green: 31, blue: 130)
                && matches(x: $0, y: bottom, red: 144, green: 31, blue: 130)
        }
        let vertical = (top...bottom).allSatisfy {
            matches(x: left, y: $0, red: 144, green: 31, blue: 130)
                && matches(x: right, y: $0, red: 144, green: 31, blue: 130)
        }
        XCTAssertTrue(horizontal && vertical, "All four border sides must be continuous", file: file, line: line)
        XCTAssertFalse(matches(x: left + Int(2 * scale), y: (top + bottom) / 2,
                               red: 144, green: 31, blue: 130), "Border remains 2 pt", file: file, line: line)
    }
}
