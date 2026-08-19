//
//  NetworkingEventMonitor.swift
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
import Utility

final class BaseEventMonitor: EventMonitor {
    let queue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier ?? "").networklogger")

    // MARK: - Multipart Upload
    func request(_ request: UploadRequest, didCreateUploadable uploadable: UploadRequest.Uploadable) {
        var body = "nil"
        if case .data(let data) = uploadable {
            body = data.toString
        }
        log.debug("uploadable: \n\(body)")
    }

    // MARK: - Response
    func requestDidFinish(_ request: Request) {
        guard let statusCode = request.response?.statusCode else {
            log.error("⛔️ Cancel: \(request.description)")
            return
        }

        log.debug("\n✅ \(request.description)\n🔸 Status code: \(statusCode)")
    }

    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        guard
            let data = response.data
        else {
            log.error("\n🔸 Data: nil")
            return
        }

        log.debug("\n🔸 Data: \(data.prettyPrintedJSONString ?? .init())")

        do {
            _ = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            log.debug("\n👍🏼 Serialization: OK")
        } catch let error {
            log.error("‼️ Serialization: \(error.localizedDescription)")
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        log.debug("progress: \(progress)")
    }
}
