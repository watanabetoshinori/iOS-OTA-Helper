//
//  LocalServer.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa

class LocalServer: NSObject {

    private var process: Process?

    private var outputPipe: Pipe?

    private var completion: ((Result<Bool>) -> Void)?

    // MARK: - Initializing a Singleton

    static let shared = LocalServer()

    override private init() {

    }

    // MARK: - Running Server

    func run(with rootDirectory: URL, completion: @escaping (Result<Bool>) -> Void) {
        self.completion = completion

        DispatchQueue.global(qos: .background).async {
            self.process = Process()
            self.process!.currentDirectoryURL = rootDirectory
            self.process!.launchPath = "/bin/sh"
            self.process!.arguments = ["-c", "python -m SimpleHTTPServer 8080;"]

            self.captureOutput(self.process!)

            self.process!.launch()

            self.process!.waitUntilExit()
        }
    }

    func handleOutput(string: String) {
        print(string)

        DispatchQueue.main.async {
            if let completion = self.completion {
                if string.hasPrefix("Serving HTTP") {
                    completion(.success(true))
                } else {
                    let error = NSError(domain: "otahelper",
                                        code: 0,
                                        userInfo: [NSLocalizedDescriptionKey: "Failed to launch local server. Local server address(8080) already in use."])
                    completion(.failure(error))
                }

                self.completion = nil
            }
        }
    }

    func stop() {
        process?.interrupt()
        process = nil
    }

    // MARK: - Capture I/O

    func captureOutput(_ process: Process) {
        outputPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = outputPipe

        outputPipe!.fileHandleForReading.waitForDataInBackgroundAndNotify()

        NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: outputPipe!.fileHandleForReading , queue: nil) { notification in
            let output = self.outputPipe!.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: .utf8) ?? ""

            DispatchQueue.main.async(execute: {
                self.handleOutput(string: outputString)
            })

            self.outputPipe!.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }

}
