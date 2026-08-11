//
//  WebViewController.swift
//  CommonUI
//
//  Created by Vyacheslav Razumeenko on 25.06.2025.
//
//  Copyright (c) 2025 EFI https://efi.int/
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

import UIKit
import WebKit
import Utility
import Resources

public class WebViewController: UIViewController {
    // MARK: - Private UI
    private lazy var webView: WKWebView = build {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isOpaque = false
        $0.uiDelegate = self
        $0.navigationDelegate = self

        let webPreferenses = WKWebpagePreferences()
        webPreferenses.allowsContentJavaScript = true
        $0.configuration.defaultWebpagePreferences = webPreferenses
    }

    // MARK: - Public Properties
    public private(set) var url: String = ""

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()

        configureSelf()
        configureConstraints()
    }

    // MARK: - Public Methods
    public func loadUrl(_ stringUrl: String) {
        self.url = stringUrl
        guard let url: URL = .init(string: stringUrl) else { return }

        let request: URLRequest = .init(url: url)

        log.debug("request: \(request)")

        webView.load(request)
    }
}

// MARK: - Private Methods
private extension WebViewController {
    func configureSelf() {
        view.backgroundColor = AppColors.Other.white.color
    }

    func configureConstraints() {
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    public func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        log.debug()
    }

    public func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        log.error("\(error.localizedDescription)")
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url,
               UIApplication.shared.canOpenURL(url) {
                log.debug("url: \(url)")
                log.debug("Redirected to browser. No need to open it locally")
            } else {
                log.debug("Open it locally")
            }
        } else {
            if let host = navigationAction.request.url?.host {
                log.debug("host: \(host)")
            } else {
                log.debug("not a user click")
            }
        }

        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate
extension WebViewController: WKUIDelegate {
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        log.debug()

        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }

        return nil
    }
}
