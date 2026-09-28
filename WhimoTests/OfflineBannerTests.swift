//
//  OfflineBannerTests.swift
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
import FactoryKit
import Networking
import SwiftUI
import CommonUI
import Resources
import FlowStacks
@testable import Whimo

@MainActor
final class OfflineBannerTests: XCTestCase {
    func testInitialConfirmedOfflineAndConnectivityChanges() async {
        let state = FilterAppStateTestDouble()
        state.navigation[\.path] = [.root(.tabBar, embedInNavigationView: true)]
        let connectivity = OfflineBannerConnectivity(.notReachable)
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.connectivity.register { connectivity }.scope(.unique)
        let model = RootOfflineBannerViewModel()
        XCTAssertEqual(model.visibleRouteIndices, [0])
        for status in [ConnectivityImpl.Status.reachable(.ethernetOrWiFi), .unknown, .notReachable] {
            connectivity.status.send(status)
            let updated = expectation(description: "Presentation updated")
            DispatchQueue.main.async { updated.fulfill() }
            await fulfillment(of: [updated], timeout: 2)
            XCTAssertEqual(model.visibleRouteIndices, status == .notReachable ? [0] : [])
        }
    }

    func testNavigationScopeAndLogoutWhileOffline() async {
        let state = FilterAppStateTestDouble()
        let connectivity = OfflineBannerConnectivity(.notReachable)
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        AppContainer.shared.appState.register { state }.scope(.unique)
        AppContainer.shared.connectivity.register { connectivity }.scope(.unique)
        let model = RootOfflineBannerViewModel()
        let paths: [(Routes<Screen>, Set<Int>)] = [
            ([.root(.login), .sheet(.changeLanguage, embedInNavigationView: false)], []),
            ([.root(.tabBar)], [0]),
            ([.root(.tabBar), .push(.transactionDetails(transactionId: "test"))], [0, 1]),
            ([.root(.tabBar), .push(.createTransaction), .push(.scanQR)], [0, 1, 2]),
            ([.root(.tabBar), .push(.addGpsPoint)], [0, 1]),
            ([.root(.tabBar), .push(.changeLanguageFullScreen)], [0, 1]),
            ([.root(.tabBar), .sheet(.changeLanguageFullScreen, embedInNavigationView: true), .push(.accountInfo)], [0]),
            ([.root(.tabBar), .cover(.scanQR, embedInNavigationView: true)], [0]),
            ([.root(.tabBar), .push(.login)], [0]),
            ([.root(.tabBar)], [0]),
            ([.root(.login)], [])
        ]
        for (path, visible) in paths {
            state.navigation[\.path] = path
            let updated = expectation(description: "Navigation updated")
            DispatchQueue.main.async { updated.fulfill() }
            await fulfillment(of: [updated], timeout: 2)
            XCTAssertEqual(model.visibleRouteIndices, visible)
        }
    }

    func testBannerKeepsFixedHeightAcrossWidthsLanguagesAndAccessibilitySizes() throws {
        let previousLanguage = UserDefaults.standard.string(forKey: "currentLocalize")
        defer { UserDefaults.standard.set(previousLanguage, forKey: "currentLocalize") }
        for language in ["en", "fr", "es"] {
            UserDefaults.standard.set(language, forKey: "currentLocalize")
            for width in [320.0, 402.0] {
                for size in [DynamicTypeSize.large, .accessibility5] {
                    let renderer = ImageRenderer(content: OfflineBanner()
                        .environment(\.dynamicTypeSize, size)
                        .frame(width: width - 32))
                    renderer.scale = 1
                    let image = try XCTUnwrap(renderer.uiImage)
                    XCTAssertEqual(image.size.width, width - 32)
                    XCTAssertEqual(image.size.height, 48)
                    let attachment = XCTAttachment(image: image)
                    attachment.name = "offline-\(language)-\(Int(width))-\(size)"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                }
            }
        }
    }

    func testSharedNavigationReservesSpaceAndConsumesBannerEnvironment() async throws {
        AppContainer.shared.manager.push()
        defer { AppContainer.shared.manager.pop() }
        let state = FilterAppStateTestDouble()
        state.navigation[\.path] = [.root(.tabBar)]
        AppContainer.shared.appState.register { state }.scope(.unique)
        let navigator = AppFlowNavigator(.constant(state.navigation.value.path))
        let previousWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        defer {
            window.isHidden = true
            previousWindow?.makeKey()
        }
        var frames: [CGRect] = []
        for offline in [false, true, false] {
            let laidOut = expectation(description: "Content laid out")
            var measuredFrame: CGRect?
            let content = BannerLayoutProbe { frame, inheritedBanner in
                XCTAssertFalse(inheritedBanner, "Nested content and its sheets must not inherit screen chrome")
                guard measuredFrame == nil else { return }

                measuredFrame = frame
                laidOut.fulfill()
            }
            .applyNavigationBar(title: "Transactions", showBackButton: false)
            .environment(\.showsOfflineBanner, offline)
            .environmentObject(navigator)
            .coordinateSpace(name: "screen")
            let host = UIHostingController(rootView: content)
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            await fulfillment(of: [laidOut], timeout: 3)
            frames.append(try XCTUnwrap(measuredFrame))
            if offline {
                let image = UIGraphicsImageRenderer(bounds: host.view.bounds).image { _ in
                    host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
                }
                let attachment = XCTAttachment(image: image)
                attachment.name = "shared-navigation-320-offline"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
        XCTAssertEqual(frames[1].minY - frames[0].minY, 80, accuracy: 0.5)
        XCTAssertEqual(frames[0].height - frames[1].height, 80, accuracy: 0.5)
        XCTAssertEqual(frames[0], frames[2], "Reconnection restores the content region")
    }

}

private final class OfflineBannerConnectivity: Connectivity {
    let status: CurrentValueSubject<ConnectivityImpl.Status, Never>
    var isReachable: AnyPublisher<ConnectivityImpl.Status, Never> { status.eraseToAnyPublisher() }
    var isReachableValue: ConnectivityImpl.Status { status.value }
    var isReachableFlag: Bool { status.value == .reachable(.ethernetOrWiFi) }

    func startObserving() {}
    func stopObserving() {}

    init(_ value: ConnectivityImpl.Status) { status = .init(value) }
}

private struct BannerLayoutProbe: View {
    @Environment(\.showsOfflineBanner) private var inheritedBanner
    let measured: (CGRect, Bool) -> Void

    var body: some View {
        Color.blue
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("screen")) } action: {
                measured($0, inheritedBanner)
            }
    }
}
