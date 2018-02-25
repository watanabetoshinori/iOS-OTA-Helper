//
//  DragAreaView.swift
//  OTAHelper
//
//  Created by Watanabe Toshinori on 2/25/18.
//  Copyright © 2018 Watanabe Toshinori. All rights reserved.
//

import Cocoa

protocol DragAreaViewDelegate {
    func dragAreaViewDidReceivingDrag(view: DragAreaView)
    func dragAreaViewDidUnreceivingDrag(view: DragAreaView)
    func dragAreaView(view: DragAreaView, ipaFile: URL)
}

class DragAreaView: NSView {

    var delegate: DragAreaViewDelegate?

    var acceptableTypes = [NSPasteboard.PasteboardType.fileURL]

    let filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: ["com.apple.iTunes.ipa"]]

    var isReceivingDrag = false {
        didSet {
            if isReceivingDrag {
                delegate?.dragAreaViewDidReceivingDrag(view: self)
            } else {
                delegate?.dragAreaViewDidUnreceivingDrag(view: self)
            }
        }
    }

    // MARK: - Initialize View

    override func awakeFromNib() {
        setup()
    }

    // MARK: - Hit Testing

    override func hitTest(_ aPoint: NSPoint) -> NSView? {
        return nil
    }

    // MARK: -

    func setup() {
        registerForDraggedTypes(acceptableTypes)
    }

    func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        let pasteBoard = draggingInfo.draggingPasteboard()

        return pasteBoard.canReadObject(forClasses: [NSURL.self], options: filteringOptions)
    }

    // MARK: - Drag Operation

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let allow = shouldAllowDrag(sender)
        isReceivingDrag = allow
        return allow ? .copy : NSDragOperation()
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isReceivingDrag = false
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let allow = shouldAllowDrag(sender)
        return allow
    }

    override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        isReceivingDrag = false

        let pasteBoard = draggingInfo.draggingPasteboard()

        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: filteringOptions) as? [URL],
            let url = urls.first {
            delegate?.dragAreaView(view: self, ipaFile: url)
            return true
        }

        return false
    }
    
}
