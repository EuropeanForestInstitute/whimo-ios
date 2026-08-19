//
//  DownloadStream.swift
//  Networking
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
import Alamofire

// MARK: - DownloadStream
public class DownloadStream: NSObject {
    // MARK: - Event
    public enum Event {
        case progress(progress: Progress)
        case success(url: URL)
        case error(AFError)
    }

    // MARK: - Public Properties
    public var events: AsyncStream<Event> {
        AsyncStream { continuation in
            self.continuation = continuation
            Task {
                await download()
            }
            continuation.onTermination = { @Sendable [weak self] _ in
                self?.task?.cancel()
            }
        }
    }

    // MARK: - Private Properties
    private let request: DownloadRequest
    private var continuation: AsyncStream<Event>.Continuation?
    private var task: DownloadTask<URL>?

    // MARK: - Init
    public init(request: DownloadRequest) {
        self.request = request
        super.init()
    }

    public func pause() {
        task?.suspend()
    }

    public func resume() {
        task?.resume()
    }
}

// MARK: - Private Properties
private extension DownloadStream {
    func download() async {
        Task {
            for await progress in request.downloadProgress() {
                continuation?.yield(.progress(progress: progress))
            }
        }

        let task = request.serializingDownloadedFileURL()
        self.task = task

        let result = await task.result

        switch result {
            case .success(let data):
                continuation?.yield(.success(url: data))
            case .failure(let error):
                continuation?.yield(.error(error))
        }
    }
}
