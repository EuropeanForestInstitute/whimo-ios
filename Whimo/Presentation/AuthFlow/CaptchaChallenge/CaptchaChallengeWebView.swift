//
//  CaptchaChallengeWebView.swift
//  Whimo
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

import SwiftUI
import WebKit

// MARK: - CaptchaChallengeWebView
struct CaptchaChallengeWebView: UIViewRepresentable {
    private static let messageHandlerName = "captcha"

    let session: CaptchaChallengeSession
    let onEffect: (CaptchaChallengeSession.Effect) -> Void

    // MARK: - UIViewRepresentable
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.userContentController.add(
            context.coordinator,
            name: Self.messageHandlerName
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        context.coordinator.attach(webView)
        webView.load(URLRequest(url: session.formURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session, onEffect: onEffect)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.cleanup()
    }
}

// MARK: - Coordinator
extension CaptchaChallengeWebView {
    final class Coordinator: NSObject {
        // MARK: - Private Properties
        private let session: CaptchaChallengeSession
        private weak var webView: WKWebView?
        private var onEffect: ((CaptchaChallengeSession.Effect) -> Void)?
        private var isCleanedUp = false

        // MARK: - Init
        init(
            session: CaptchaChallengeSession,
            onEffect: @escaping (CaptchaChallengeSession.Effect) -> Void
        ) {
            self.session = session
            self.onEffect = onEffect
        }

        // MARK: - Public Methods
        func attach(_ webView: WKWebView) {
            self.webView = webView
        }

        func cleanup() {
            guard !isCleanedUp else { return }

            isCleanedUp = true

            webView?.stopLoading()
            webView?.navigationDelegate = nil
            webView?.uiDelegate = nil
            webView?.configuration.userContentController.removeScriptMessageHandler(
                forName: CaptchaChallengeWebView.messageHandlerName
            )
            webView = nil
            onEffect = nil
        }
    }
}

// MARK: - Private Methods
private extension CaptchaChallengeWebView.Coordinator {
    func finish(with effect: CaptchaChallengeSession.Effect) {
        guard case .finish = effect else { return }

        let callback = onEffect
        cleanup()
        callback?(effect)
    }

    func sourceURL(for securityOrigin: WKSecurityOrigin) -> URL? {
        var components = URLComponents()
        components.scheme = securityOrigin.protocol
        components.host = securityOrigin.host
        if securityOrigin.port != 0 {
            components.port = securityOrigin.port
        }
        return components.url
    }
}

// MARK: - WKScriptMessageHandler
extension CaptchaChallengeWebView.Coordinator: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard
            message.name == CaptchaChallengeWebView.messageHandlerName,
            let body = message.body as? String,
            let sourceURL = sourceURL(for: message.frameInfo.securityOrigin)
        else {
            finish(with: session.handleNavigationFailure())
            return
        }

        finish(with: session.handleBridgeMessage(body: body, sourceURL: sourceURL))
    }
}

// MARK: - WKNavigationDelegate
extension CaptchaChallengeWebView.Coordinator: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.targetFrame?.isMainFrame != false else {
            decisionHandler(.allow)
            return
        }

        guard
            let url = navigationAction.request.url,
            session.allowsTopLevelNavigation(to: url)
        else {
            decisionHandler(.cancel)
            finish(with: session.handleNavigationFailure())
            return
        }

        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        finish(with: session.handleNavigationFailure())
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        finish(with: session.handleNavigationFailure())
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        finish(with: session.handleNavigationFailure())
    }
}
