//
//  UIKitFriendly.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa

class NSLabel: NSTextField {

    var text: String {
        get {
            return stringValue
        }
        set {
            stringValue = newValue
        }
    }

}

extension NSViewController {

    public func performSegue(withIdentifier identifier: String, sender: Any?) {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: identifier), sender: sender)
    }

}

extension NSImageView {

    var tintColor: NSColor {
        get {
            return NSColor()
        }
        set {
            guard let templateImage = self.image?.copy() as? NSImage else {
                return
            }

            templateImage.lockFocus()
            newValue.set()

            let imageRect = NSRect(origin: NSZeroPoint, size: templateImage.size)
            imageRect.fill(using: .sourceAtop)

            templateImage.unlockFocus()
            templateImage.isTemplate = false

            self.image = templateImage
        }
    }

}
