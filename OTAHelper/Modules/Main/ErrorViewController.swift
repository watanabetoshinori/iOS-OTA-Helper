//
//  ErrorViewController.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa

class ErrorViewController: NSViewController {

    @IBOutlet weak var errorDescriptionLabel: NSLabel!

    var error: Error!

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        errorDescriptionLabel.text = error.localizedDescription
    }

    // MARK: - Actions

    @IBAction func dismissTapped(_ sender: Any) {
        dismiss(nil)
    }

}
