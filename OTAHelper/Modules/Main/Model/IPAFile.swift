//
//  IPAFile.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa
import ZipArchive

class IPAFile: NSObject {

    var fileURL: URL!

    var fileName = ""

    var version = ""

    var shortVersion = ""

    var identifier = ""

    var displayName = ""

    var appURL: URL!

    var appIconFileURL: URL?

    // MARK: - Load ipa File

    class func load(from ipaFileURL: URL, in workingDirectoryURL: URL, completion: (Result<IPAFile>) -> Void) {
        let ipaFileName = ipaFileURL.lastPathComponent

        // Copy and extract ipa file
        let tempIpaFileURL = workingDirectoryURL.appendingPathComponent(ipaFileName)

        do {
            try FileManager.default.copyItem(at: ipaFileURL, to: tempIpaFileURL)

        } catch {
            let error = NSError(domain: "otahelper",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to copy ipa file to work directory."])
            completion(.failure(error))
            return
        }

        let za = ZipArchive()
        if za.unzipOpenFile(tempIpaFileURL.path) {
            if za.unzipFile(to: workingDirectoryURL.path, overWrite: true) == false {
                let error = NSError(domain: "otahelper",
                                    code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: "Failed to extract ipa file. Please check ipa file is correct."])
                completion(.failure(error))
                return
            }
            za.unzipCloseFile()
        }

        // Load data from Payload
        let payloadURL = workingDirectoryURL.appendingPathComponent("Payload")

        var appFile = ""
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: payloadURL.path)
            appFile = contents.first(where: { ($0 as NSString).pathExtension == "app" }) ?? ""
        } catch {
            let error = NSError(domain: "otahelper",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to read Payload. Please check ipa file is correct."])
            completion(.failure(error))
            return
        }

        if appFile.isEmpty {
            let error = NSError(domain: "otahelper",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to extract ipa file. Please check ipa file is correct."])
            completion(.failure(error))
            return
        }

        let appURL = payloadURL.appendingPathComponent(appFile)

        let ipa = IPAFile()

        ipa.fileName = ipaFileName
        ipa.fileURL = tempIpaFileURL
        ipa.appURL = appURL

        let infoPlistFileURL = appURL.appendingPathComponent("Info.plist")
        if let infoPlist = NSDictionary(contentsOfFile: infoPlistFileURL.path) {
            ipa.version = infoPlist["CFBundleVersion"] as? String ?? ""
            ipa.shortVersion = infoPlist["CFBundleShortVersionString"] as? String ?? ""
            ipa.identifier = infoPlist["CFBundleIdentifier"] as? String ?? ""
            ipa.displayName = {
                if let displayName = infoPlist["CFBundleDisplayName"] as? String {
                    return displayName
                }
                return infoPlist["CFBundleName"] as? String ?? ""
            }()
        }

        ipa.appIconFileURL = {
            let fileNames = ["iTunesArtwork",
                             "Icon.png",
                             "AppIcon60x60@3x.png",
                             "AppIcon60x60@2x.png",
                             "AppIcon60x60.png"]

            if let file = fileNames.first(where: { FileManager.default.fileExists(atPath: appURL.appendingPathComponent($0).path) }) {
                return appURL.appendingPathComponent(file)
            }

            return nil
        }()

        completion(.success(ipa))
    }

    // MARK: - Copying Files

    func copyProvisioningFile(to outputDirectoryURL: URL) {
        let sourceFileURL = appURL.appendingPathComponent("embedded.mobileprovision")
        let outputFileURL = outputDirectoryURL.appendingPathComponent("embedded.mobileprovision")

        do {
            try FileManager.default.copyItem(at: sourceFileURL, to: outputFileURL)
        } catch {
            print(error)
        }
    }

    func coptyIconFile(to outputDirectoryURL: URL) {
        if let appIconFileURL = appIconFileURL {
            let outputFileURL = outputDirectoryURL.appendingPathComponent("icon.png")

            do {
                try FileManager.default.copyItem(at: appIconFileURL, to: outputFileURL)
            } catch {
                print(error)
            }
        }
    }

}
