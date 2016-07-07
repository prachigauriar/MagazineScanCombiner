//
//  FileDropImageView.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/3/2016.
//  Copyright © 2016 Prachi Gauriar.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Cocoa


protocol FileDropImageViewDelegate {
    func fileDropImageView(imageView: FileDropImageView, shouldAcceptDraggedFileURL fileURL: NSURL) -> Bool
    func fileDropImageView(imageView: FileDropImageView, didReceiveDroppedFileURL fileURL: NSURL)
}


class FileDropImageView: NSImageView {
    var delegate: FileDropImageViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([kUTTypeFileURL as String])
    }


    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([kUTTypeFileURL as String])
    }


    override func drawRect(dirtyRect: NSRect) {
        if highlighted {
            NSColor.grayColor().colorWithAlphaComponent(0.2).setFill()
            let highlighRectPath = NSBezierPath(rect: bounds.insetBy(dx: 2, dy: 2))
            highlighRectPath.fill()
        }

        super.drawRect(dirtyRect)
    }


    // MARK: - Drag Handling

    private func fileURLForDraggingInfo(draggingInfo: NSDraggingInfo) -> NSURL? {
        guard draggingInfo.draggingPasteboard().pasteboardItems?.count == 1,
            let fileURL = NSURL.init(fromPasteboard: draggingInfo.draggingPasteboard()) where fileURL.fileURL else {
                return nil
        }

        guard let delegate = delegate else {
            return fileURL
        }

        return delegate.fileDropImageView(self, shouldAcceptDraggedFileURL: fileURL) ? fileURL : nil
    }


    private func iconForFileURL(fileURL: NSURL) -> NSImage? {
        guard let filePath = fileURL.path else {
            return nil
        }

        return NSWorkspace.sharedWorkspace().iconForFile(filePath)
    }


    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        guard let _ = fileURLForDraggingInfo(sender) else {
            return .None
        }

        highlighted = true
        needsDisplay = true

        return .Copy
    }


    override func draggingEnded(sender: NSDraggingInfo?) {
        highlighted = false
        needsDisplay = true
    }


    override func draggingExited(sender: NSDraggingInfo?) {
        highlighted = false
        needsDisplay = true
    }


    override func prepareForDragOperation(sender: NSDraggingInfo) -> Bool {
        return fileURLForDraggingInfo(sender) != nil
    }


    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        guard let fileURL = fileURLForDraggingInfo(sender) else {
            return false
        }

        if NSImage.canInitWithPasteboard(sender.draggingPasteboard()) {
            image = NSImage.init(pasteboard: sender.draggingPasteboard())
        } else {
            image = iconForFileURL(fileURL)
        }

        delegate?.fileDropImageView(self, didReceiveDroppedFileURL: fileURL)
        return true
    }
}
