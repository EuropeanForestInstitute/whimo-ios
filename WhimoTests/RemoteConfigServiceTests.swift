//
//  RemoteConfigServiceTests.swift
//  WhimoTests
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
@testable import Whimo

final class RemoteConfigServiceTests: XCTestCase {
    private var client: RemoteConfigClientMock!
    private var service: FirebaseRemoteConfigService!

    override func setUpWithError() throws {
        client = .init()
        service = .init(client: client)
    }

    override func tearDownWithError() throws {
        service = nil
        client = nil
    }

    func testConfigureRegistersRegistrationPhoneRegionPolicyDefault() {
        service.configure()

        XCTAssertEqual(
            client.defaults[RemoteConfigKey.registrationPhoneRegionPolicy.rawValue] as? String,
            "{\"schemaVersion\":1,\"enabled\":true,\"allowedRegions\":[]}"
        )
    }

    func testConfigureUsesImmediateFetchInterval() {
        service.configure()

        XCTAssertEqual(client.minimumFetchInterval, 0)
    }

    func testRegistrationPhoneRegionPolicyDecodesConfigValue() {
        client.values[RemoteConfigKey.registrationPhoneRegionPolicy.rawValue] = """
        {
          "schemaVersion": 1,
          "enabled": true,
          "allowedRegions": [
            {
              "regionCode": "AO",
              "regionName": "Angola",
              "callingCode": 244,
              "e164Prefix": "+244"
            },
            {
              "regionCode": "GT",
              "regionName": "Guatemala",
              "callingCode": 502,
              "e164Prefix": "+502"
            }
          ]
        }
        """

        XCTAssertEqual(
            service.registrationPhoneRegionPolicy,
            .init(
                schemaVersion: 1,
                enabled: true,
                allowedRegions: [
                    .init(
                        regionCode: "AO",
                        regionName: "Angola",
                        callingCode: 244,
                        e164Prefix: "+244"
                    ),
                    .init(
                        regionCode: "GT",
                        regionName: "Guatemala",
                        callingCode: 502,
                        e164Prefix: "+502"
                    )
                ]
            )
        )
    }

    func testRegistrationPhoneRegionPolicyUsesDefaultForMalformedConfigValue() {
        client.values[RemoteConfigKey.registrationPhoneRegionPolicy.rawValue] = "not-json"

        XCTAssertEqual(
            service.registrationPhoneRegionPolicy,
            RemoteConfigDefaults.registrationPhoneRegionPolicy
        )
    }

    func testRegistrationPhoneRegionPolicyUsesFailClosedDefaultWhenConfigValueIsMissing() {
        XCTAssertEqual(
            service.registrationPhoneRegionPolicy,
            RemoteConfigDefaults.registrationPhoneRegionPolicy
        )
        XCTAssertTrue(service.registrationPhoneRegionPolicy.enabled)
        XCTAssertTrue(service.registrationPhoneRegionPolicy.allowedRegions.isEmpty)
    }

    func testRegistrationPhoneRegionPolicyUsesDefaultForUnsupportedSchema() {
        client.values[RemoteConfigKey.registrationPhoneRegionPolicy.rawValue] = """
        {"schemaVersion":2,"enabled":true,"allowedRegions":[]}
        """

        XCTAssertEqual(
            service.registrationPhoneRegionPolicy,
            RemoteConfigDefaults.registrationPhoneRegionPolicy
        )
    }

    func testFetchAndActivateRequestsClient() async {
        await service.fetchAndActivate()

        XCTAssertEqual(client.fetchAndActivateCallCount, 1)
    }

    func testFetchAndActivateCanRetryAfterFailure() async {
        client.fetchAndActivateError = RemoteConfigClientMockError.fetchFailed

        await service.fetchAndActivate()

        client.fetchAndActivateError = nil
        await service.fetchAndActivate()

        XCTAssertEqual(client.fetchAndActivateCallCount, 2)
    }
}

private final class RemoteConfigClientMock: RemoteConfigClient {
    var defaults: [String: NSObject] = [:]
    var minimumFetchInterval: TimeInterval?
    var values: [String: String] = [:]
    var fetchAndActivateCallCount: Int = 0
    var fetchAndActivateError: Error?

    func configure(
        defaults: [String: NSObject],
        minimumFetchInterval: TimeInterval
    ) {
        self.defaults = defaults
        self.minimumFetchInterval = minimumFetchInterval
    }

    func fetchAndActivate() async throws {
        fetchAndActivateCallCount += 1

        if let fetchAndActivateError {
            throw fetchAndActivateError
        }
    }

    func stringValue(for key: String) -> String {
        values[key] ?? ""
    }
}

private enum RemoteConfigClientMockError: Error {
    case fetchFailed
}
