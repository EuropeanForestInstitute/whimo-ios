//
//  CaptchaChallengeView.swift
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
import Resources

private typealias Module = CaptchaChallengeModule
private typealias Localization = AppLocale.CaptchaChallenge

// MARK: - MainView
extension Module {
    struct MainView: View {
        // MARK: - Dependencies
        @Environment(\.dismiss) private var dismiss
        @Inject(\.appState) private var appState

        // MARK: - Private Properties
        @State private var isFinished = false
        @State private var session: CaptchaChallengeSession

        private let onOutcome: (Outcome) -> Void

        // MARK: - Init
        init(formURL: URL, onOutcome: @escaping (Outcome) -> Void) {
            _session = State(
                initialValue: CaptchaChallengeSession(formURL: formURL)
            )
            self.onOutcome = onOutcome
        }

        // MARK: - Body
        var body: some View {
            NavigationStack {
                CaptchaChallengeWebView(
                    session: session,
                    onEffect: handleEffect
                )
                .ignoresSafeArea(.container, edges: .bottom)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localization.close, action: cancel)
                    }
                }
            }
        }
    }
}

// MARK: - Private Methods
private extension Module.MainView {
    func handleEffect(_ effect: CaptchaChallengeSession.Effect) {
        guard let outcome = Module.outcome(for: effect) else { return }

        finish(with: outcome, showsError: outcome == .failure)
    }

    func cancel() {
        handleEffect(session.cancel())
    }

    func finish(with outcome: Module.Outcome, showsError: Bool = false) {
        guard !isFinished else { return }

        isFinished = true

        dismiss()
        onOutcome(outcome)

        if showsError {
            appState.showError(message: Localization.error)
        }
    }
}

// MARK: - Previews
#if !RELEASE
struct CaptchaChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        CaptchaChallengeModule.assemble { _ in }
    }
}
#endif
