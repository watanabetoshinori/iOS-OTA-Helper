//
//  HTMLFile.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa

class HTMLFile: NSObject {

    private var htmlString = ""

    // MARK: - Initialize

    override private init() {

    }

    // MARK: - Generate HTML File

    class func generate(ipa: IPAFile, publicURL: URL) -> HTMLFile {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())

        let manifestFile = (publicURL.absoluteString + "/" + "manifest.plist")

        // Load template
        let templateFilePath = Bundle.main.path(forResource: "index_template", ofType: "html")!
        var templateString = try! String(contentsOfFile: templateFilePath)

        // Replace values
        templateString = templateString.replacingOccurrences(of: "___NAME___", with: ipa.displayName)
        templateString = templateString.replacingOccurrences(of: "___VERSION___", with: ipa.version)
        templateString = templateString.replacingOccurrences(of: "___PLIST___", with: manifestFile )
        templateString = templateString.replacingOccurrences(of: "___DATE___", with: dateString)
        if ipa.appIconFileURL != nil {
            templateString = templateString.replacingOccurrences(of: "___ICON___", with: "<p><img src='icon.png' length='57' width='57' /></p>")
        } else {
            templateString = templateString.replacingOccurrences(of: "___ICON___", with: "")
        }

        let html = HTMLFile()
        html.htmlString = templateString
        return html
    }

    // MARK: - Save HTML File

    func save(to outputDirectoryURL: URL) {
        let outputFileURL = outputDirectoryURL.appendingPathComponent("index.html")
        do {
            try htmlString.write(to: outputFileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print(error)
        }
    }

}
