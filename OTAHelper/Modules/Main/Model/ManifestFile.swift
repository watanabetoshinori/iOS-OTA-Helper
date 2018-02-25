//
//  ManifestFile.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa

class ManifestFile: NSObject {

    private var dictionary = [String: [[String: Any]]]()

    // MARK: - Initialize

    override private init() {

    }

    // MARK: - Generate Manifest File

    class func generate(ipa: IPAFile, publicURL: URL) -> ManifestFile {
        // Generate Assets
        var assets = [[String: String]]()

        if let encodedIpaFileName = (ipa.fileName as NSString).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            let url = (publicURL.absoluteString + "/" + encodedIpaFileName)
            assets.append(["kind": "software-package",
                           "url": url])
        }

        if let appIconFileURL = ipa.appIconFileURL {
            let fileName = appIconFileURL.lastPathComponent
            let url = (publicURL.absoluteString + "/" + fileName)

            assets.append(["kind": "display-image",
                           "url": url])
            assets.append(["kind": "full-size-image",
                           "url": url])
        }

        // Generate Manifest
        let manifest = ManifestFile()
        manifest.dictionary = [
            "items": [
                [
                    "assets": assets,
                    "metadata": [
                        "bundle-identifier": ipa.identifier,
                        "bundle-version": ipa.version,
                        "kind": "software",
                        "title": ipa.displayName,
                    ],
                ]
            ]
        ]
        return manifest
    }

    // MARK: - Save Manifest File

    func save(to outputDirectoryURL: URL) {
        let outputFileURL = outputDirectoryURL.appendingPathComponent("manifest.plist")
        (dictionary as NSDictionary).write(to: outputFileURL, atomically: true)
    }
    
}
