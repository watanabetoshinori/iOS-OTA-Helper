//
//  SecureTunnel.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa

class SecureTunnel: NSObject {

    private var process: Process?

    private var outputPipe: Pipe?

    private var completion: ((Result<URL>) -> Void)?

    // MARK: - Initializing a Singleton

    static let shared = SecureTunnel()

    override private init() {

    }

    // MARK: - Running Server

    func run(with rootDirectory: URL, username: String, password: String, completion: @escaping (Result<URL>) -> Void) {
        self.completion = completion

        let arguments: [String] = {
            if username.isEmpty == false, password.isEmpty == false {
                return ["http", "-bind-tls=true", "-auth=\"\(username):\(password)\"", "8080"]
            }
            return ["http", "-bind-tls=true", "8080"]
        }()

        DispatchQueue.global(qos: .background).async {
            self.process = Process()
            self.process!.currentDirectoryURL = rootDirectory
            self.process!.launchPath = "/usr/local/bin/ngrok"
            self.process!.arguments = arguments

            self.captureOutput(self.process!)

            self.process!.launch()

            // Wait 2.0 sec to connect ngrok
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.loadPublicURL(completion: { (url) in
                    DispatchQueue.main.async {
                        if let url = url {
                            completion(.success(url))
                        } else {
                            let error = NSError(domain: "otahelper",
                                                code: 0,
                                                userInfo: [NSLocalizedDescriptionKey: "Failed to launch ngrok. Can't connect to the ngrok API."])
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

        if let completion = completion {
            if string.hasPrefix("/bin/sh:") {
                let error = NSError(domain: "otahelper",
                                    code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: "Ngrok not insatalled. Please check ngrok is installed."])
                completion(.failure(error))
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

    // MARK: - Getting Tunnel Status

    func loadPublicURL(completion: @escaping (URL?) -> Void) {
        let url = URL(string: "http://127.0.0.1:4040/api/tunnels")!
        let request = URLRequest(url: url)

        let task = URLSession.shared.dataTask(with: request) { (data, respinse, error) in
            guard let data = data else {
                completion(nil)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

                if let json = json as? [String: Any],
                    let tunnels = json["tunnels"] as? [[String: Any]],
                    let tunnel = tunnels.first,
                    let publicURL = tunnel["public_url"] as? String,
                    let url = URL(string: publicURL) {

                    completion(url)
                    return
                }

            } catch {
                print(error)
            }

            completion(nil)
        }

        task.resume()
    }

}
