//
//  AddGpsPointViewModel.swift
//  Whimo
//
//  Created by Vyacheslav Razumeenko on 07.05.2025.
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
import Utility
import MapKit

private typealias Module = AddGpsPointModule
private typealias ViewModel = Module.ViewModel

// MARK: - ViewModel
extension Module {
    final class ViewModel: ViewModelProtocol {
        private enum Constants {
            static let defaultMapZoom: MKCoordinateSpan = .init(latitudeDelta: 0.05, longitudeDelta: 0.05)

            static let defaultLocation: MKCoordinateRegion = .init(
                center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
                span: defaultMapZoom
            )
        }

        // MARK: - Public Properties
        @Published var selectedRegion: MKCoordinateRegion = Constants.defaultLocation

        // MARK: - Private Properties
        private var cancellable: CancelBag = .init()

        // MARK: - Dependencies
        @Inject(\.appState) private var appState
        @Inject(\.locationService) private var locationService

        // MARK: - Init
        init() {
            startup()
        }

        // MARK: - ViewModelProtocol
        func didTapConfirmAddGPS() {
            appState.createTransaction[\.farmLocation] = .manual(coordinates: selectedRegion.center)
            appState.navigation[\.path].removeLast(2)
        }
    }
}

// MARK: - Private Methods
private extension ViewModel {
    // MARK: - Setup
    func startup() {
        Task { [weak self] in
            try await self?.fetchUserLocation()
        }
    }

    // MARK: - Common
    func fetchUserLocation() async throws {
        var coordinate: CLLocationCoordinate2D
        if case .gps(let coordinates) = appState.createTransaction.value.farmLocation {
            coordinate = coordinates
        } else {
            coordinate = await locationService.getUserLocation()?.coordinate ?? Constants.defaultLocation.center
        }

        await MainActor.run { [coordinate] in
            selectedRegion = MKCoordinateRegion(
                center: coordinate,
                span: Constants.defaultMapZoom
            )
        }
    }
}
