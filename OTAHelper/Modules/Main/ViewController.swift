//
//  ViewController.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    let defaultDragAreaTintColor = NSColor(deviceRed: 191/255, green: 191/255, blue: 191/255, alpha: 1.0)

    let selectedDragAreaTintColor = NSColor(deviceRed: 74/255, green: 144/255, blue: 226/255, alpha: 1.0)

    @IBOutlet weak var label: NSLabel!

    @IBOutlet weak var dragAreaView: DragAreaView!

    @IBOutlet weak var dragAreaImage: NSImageView!

    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    @IBOutlet weak var usernameField: NSTextField!

    @IBOutlet weak var passwordField: NSTextField!

    private var ipaFileURL: URL?

    private var publicURL: URL?

    private var workingDirectoryURL: URL?

    private var error: Error?

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        initializeView()
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch (segue.destinationController, segue.identifier?.rawValue) {
        case (let viewController as ResultViewController, "ShowResultScreen"?):
            viewController.workingDirectoryURL = self.workingDirectoryURL!
            viewController.publicURL = self.publicURL!

        case (let viewController as ErrorViewController, "ShowErrorScreen"?):
            viewController.error = self.error!

        default:
            break
        }
    }

    // MARK: - Update View

    func initializeView() {
        dragAreaView.delegate = self

        dragAreaImage.tintColor = defaultDragAreaTintColor

        progressIndicator.isHidden = true
    }

    func startLoading() {
        dragAreaView.isHidden = true
        dragAreaImage.isHidden = true

        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)

        label.text = "Stating OTA server..."
    }

    func stopLoading() {
        dragAreaView.isHidden = false
        dragAreaImage.isHidden = false

        progressIndicator.isHidden = true
        progressIndicator.stopAnimation(nil)

        label.text = "Drag ipa file here"
    }

    // MARK: - Move to Other screen

    func showResult(with workingDirectoryURL: URL, publicURL: URL) {
        self.workingDirectoryURL = workingDirectoryURL
        self.publicURL = publicURL

        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "ShowResultScreen", sender: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.stopLoading()
            }
        }
    }

    func showError(_ error: Error) {
        self.error = error

        SecureTunnel.shared.stop()
        LocalServer.shared.stop()

        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "ShowErrorScreen", sender: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.stopLoading()
            }
        }
    }

}

// MARK: - DragAreaView Delegate

extension ViewController: DragAreaViewDelegate {

    func dragAreaViewDidReceivingDrag(view: DragAreaView) {
        dragAreaImage.tintColor = selectedDragAreaTintColor
    }

    func dragAreaViewDidUnreceivingDrag(view: DragAreaView) {
        dragAreaImage.tintColor = defaultDragAreaTintColor
    }

    func dragAreaView(view: DragAreaView, ipaFile: URL) {
        self.ipaFileURL = ipaFile

        startLoading()

        prepareWorkingDirectory()
     }

}

// MARK: - OTA

extension ViewController {

    func prepareWorkingDirectory() {
        let uuid = UUID().uuidString
        let workingDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(uuid))

        print("workingDirectoryURL: \(workingDirectoryURL.path)")

        do {
            if FileManager.default.fileExists(atPath: workingDirectoryURL.path) {
                try FileManager.default.removeItem(atPath: workingDirectoryURL.path)
            }

            try FileManager.default.createDirectory(at: workingDirectoryURL, withIntermediateDirectories: true, attributes: nil)

        } catch {
            self.showError(error)
        }

        runLocalServer(with: workingDirectoryURL)
    }

    func runLocalServer(with workingDirectoryURL: URL) {
        LocalServer.shared.run(with: workingDirectoryURL) { (result) in
            switch result {
            case .success:
                self.runTunnel(with: workingDirectoryURL)

            case .failure(let error):
                self.showError(error)
            }
        }
    }

    func runTunnel(with workingDirectoryURL: URL) {
        let username = usernameField.stringValue
        let password = passwordField.stringValue

        SecureTunnel.shared.run(with: workingDirectoryURL, username: username, password: password) { (result) in
            switch result {
            case .success(let publicURL):
                print("publicURL: \(publicURL.absoluteString)")

                self.generateContents(with: workingDirectoryURL, publicURL: publicURL)

            case .failure(let error):
                self.showError(error)
            }
        }
    }

    func generateContents(with workingDirectoryURL: URL, publicURL: URL) {
        IPAFile.load(from: ipaFileURL!, in: workingDirectoryURL) { (result) in
            switch result {
            case .success(let ipa):
                ipa.coptyIconFile(to: workingDirectoryURL)

                let manifest = ManifestFile.generate(ipa: ipa, publicURL: publicURL)
                manifest.save(to: workingDirectoryURL)

                let indexHTML = HTMLFile.generate(ipa: ipa, publicURL: publicURL)
                indexHTML.save(to: workingDirectoryURL)

                showResult(with: workingDirectoryURL, publicURL: publicURL)

            case .failure(let error):
                self.showError(error)
            }
        }
    }

}
