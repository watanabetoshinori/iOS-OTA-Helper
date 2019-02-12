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
            self.process!.launchPath = "/bin/bash"
            self.process!.arguments = ["-l", "-c", "python -m SimpleHTTPServer 8080;"]

            self.captureOutput(self.process!)

            self.process!.launch()

            // Wait 5.0 sec to connect local server
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.loadURL(completion: { (result) in
                    DispatchQueue.main.async {
                        if result {
                            completion(.success(true))

                        } else {
                            let error = NSError(domain: "otahelper",
                                                code: 0,
                                                userInfo: [NSLocalizedDescriptionKey: "Failed to launch local server."])
                            completion(.failure(error))
                        }

                        self.completion = nil
                    }
                })
            }
        }
    }

    func handleOutput(string: String) {
        print(string)

        DispatchQueue.main.async {
            if let completion = self.completion {
                if string.hasPrefix("Serving HTTP") || string.hasPrefix("127.0.0.1") {
                    return
                } else {
                    let error = NSError(domain: "otahelper",
                                        code: 0,
                                        userInfo: [NSLocalizedDescriptionKey: "Failed to launch local server."])
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

    // MARK: - Load Local server

    func loadURL(completion: @escaping (Bool) -> Void) {
        let url = URL(string: "http://127.0.0.1:8080/")!
        let request = URLRequest(url: url)

        let task = URLSession.shared.dataTask(with: request) { (data, respinse, error) in
            if data != nil {
                completion(true)
                return
            }

            completion(false)
        }

        task.resume()
    }

}
