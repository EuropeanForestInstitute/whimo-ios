//
//  HapticsEngineService.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 28.04.2025.
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

import Foundation
import class UIKit.UIImpactFeedbackGenerator
import CoreHaptics
import Utility

final class HapticsEngineService: HapticsEngineServiceProtocol {
    // MARK: - HapticParameters
    struct HapticParameters {
        static let `default`: HapticParameters = .init(intensity: 1, sharpness: 2)

        let intensity: Float
        let sharpness: Float
    }

    // MARK: - Private Properties
    private var engine: CHHapticEngine?

    // MARK: - Init
    init() { }

    // MARK: - HapticsEngineServiceProtocol
    @discardableResult
    func produceHaptic(with params: HapticParameters) async -> HapticsError? {
        let task = Task(priority: .userInitiated) {
            _produceHaptic(params)
        }

        return await task.value
    }

    func produceButtonImpact() {
        log.debug()

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Private Methods
private extension HapticsEngineService {
    @discardableResult
    // swiftlint:disable:next identifier_name
    func _produceHaptic(_ params: HapticParameters) -> HapticsError? {
        let setupError = setupEngine()
        if let setupError {
            return setupError
        }
        log.debug()

        var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: params.intensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: params.sharpness)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: .zero
        )
        events.append(event)

        var patternsInitialized = false
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            patternsInitialized = true
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: .zero)

            return nil
        } catch {
            let error: HapticsError = patternsInitialized ? .engineStartFailure(error: error) : .patternsInitFailure(error: error)
            log.error("An error occurred: \(error.localizedDescription).")
            return error
        }
    }

    func setupEngine() -> HapticsError? {
        log.debug()
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            log.debug("Device does not support haptics")
            return .hapticsUnsupported
        }

        var initialized = false
        do {
            engine = try CHHapticEngine()
            initialized = true
            try engine?.start()

            return nil
        } catch {
            let error: HapticsError = initialized ? .engineStartFailure(error: error) : .engineInitFailure(error: error)
            log.error("An error occurred: \(error.localizedDescription)")
            return error
        }
    }
}
