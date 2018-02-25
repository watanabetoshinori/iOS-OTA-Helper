//
//  ResultViewController.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa

class ResultViewController: NSViewController {

    @IBOutlet weak var publicURLLabel: NSLabel!

    @IBOutlet weak var qrCodeImageView: NSImageView!

    var workingDirectoryURL: URL!

    var publicURL: URL!

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.publicURLLabel.text = publicURL.absoluteString

        self.qrCodeImageView.image = generateQRcode(string: publicURL.absoluteString)
    }

    // MARK: - Actions

    @IBAction func stopServerTapped(_ sender: Any) {
        SecureTunnel.shared.stop()
        LocalServer.shared.stop()

        do {
            try FileManager.default.removeItem(at: workingDirectoryURL)
        } catch {
            print(error)
        }

        dismiss(nil)
    }

    func generateQRcode(string: String) -> NSImage? {
        let data = string.data(using: .utf8)

        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data , forKey: "inputMessage")

        guard let ciImage = filter?.outputImage else {
            return nil
        }

        let rep = NSCIImageRep(ciImage: ciImage)
        let tinyImage = NSImage()
        tinyImage.addRepresentation(rep)

        let nsImage = NSImage(size: NSSize(width: 101, height: 101))
        nsImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = NSImageInterpolation.none
        tinyImage.draw(in: NSRect(x: 0, y: 0, width: 101, height: 101))
        nsImage.unlockFocus()

        return nsImage
    }
    
}
