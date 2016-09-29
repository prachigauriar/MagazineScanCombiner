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


/// The `FileDropImageViewDelegate` protocol allows users of `FileDropImageViews` to be notified when
/// a file has been dropped on the image view as well as controlling which file URLs are acceptable.
protocol FileDropImageViewDelegate {
    /// Returns whether the file drop image view should accept a drop for the specified file URL.
    /// This method can be used to allow only certain files, e.g., only files with a given type or
    /// file extension, or files located in a certain area of the file system. For example, to only
    /// accept spreadsheets, your implementation may look like:
    ///
    /// ```
    /// guard let resourceValues = try? fileURL.resourceValues(forKeys: [URLResourceKey.typeIdentifierKey]),
    ///     let fileType = resourceValues.typeIdentifier else {
    ///         return false
    /// }
    ///
    /// return UTTypeConformsTo(fileType as CFString, kUTTypeSpreadsheet)
    /// ```
    ///
    /// - parameter imageView: The file drop image view.
    /// - parameter fileURL: A file URL for the file being dragged onto the image view.
    /// - returns: Whether the image view should accept the file.
    func fileDropImageView(_ imageView: FileDropImageView, shouldAcceptDraggedFileURL fileURL: URL) -> Bool

    /// Notifies the receiver that the specified file URL has been dropped on the file drop image view.
    ///
    /// - parameter imageView: The file drop image view.
    /// - parameter fileURL: The file URL for the file that was dropped.
    func fileDropImageView(_ imageView: FileDropImageView, didReceiveDroppedFileURL fileURL: URL)
}


/// `FileDropImageView` instances make it easy to receive file URLs from the user via a
/// drag-and-drop interface and display the file’s icon. When a file is dragged onto an image view,
/// the image view asks its delegate whether the file URL is an acceptable type. If it is and the
/// file is dropped onto the instance, the file drop image view will update its image to the file’s
/// icon or a thumbnail of the file’s contents if the file is an image. It will then notify the
/// delegate of the dropped file’s URL.
@IBDesignable class FileDropImageView : NSImageView {
    /// The instance’s delegate
    var delegate: FileDropImageViewDelegate?

    private var _fileURL: URL?

    /// The instance’s file URL
    var fileURL: URL? {
        get { return _fileURL }
        set {
            _fileURL = newValue
            image = icon(for: newValue)
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        register(forDraggedTypes: [kUTTypeFileURL as String])
    }


    required init?(coder: NSCoder) {
        super.init(coder: coder)
        register(forDraggedTypes: [kUTTypeFileURL as String])
    }


    override func draw(_ dirtyRect: NSRect) {
        if isHighlighted {
            NSColor.gray.withAlphaComponent(0.2).setFill()
            let highlighRectPath = NSBezierPath(rect: bounds.insetBy(dx: 2, dy: 2))
            highlighRectPath.fill()
        }

        super.draw(dirtyRect)
    }


    // MARK: - Drag Handling

    private func fileURL(for draggingInfo: NSDraggingInfo) -> URL? {
        guard draggingInfo.draggingPasteboard().pasteboardItems?.count == 1,
            let fileURL = URL(from: draggingInfo.draggingPasteboard()),
            fileURL.isFileURL else {
                return nil
        }

        guard let delegate = delegate else {
            return fileURL as URL
        }

        return delegate.fileDropImageView(self, shouldAcceptDraggedFileURL: fileURL) ? fileURL : nil
    }


    private func icon(for fileURL: URL?) -> NSImage? {
        guard let filePath = fileURL?.path else {
            return nil
        }

        return NSWorkspace.shared().icon(forFile: filePath)
    }


    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let _ = fileURL(for: sender) else {
            return NSDragOperation()
        }

        isHighlighted = true
        needsDisplay = true

        return .copy
    }


    override func draggingEnded(_ sender: NSDraggingInfo?) {
        isHighlighted = false
        needsDisplay = true
    }


    override func draggingExited(_ sender: NSDraggingInfo?) {
        isHighlighted = false
        needsDisplay = true
    }


    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return fileURL(for: sender) != nil
    }


    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let fileURL = fileURL(for: sender) else {
            return false
        }

        // Set _fileURL instead of fileURL so that we don’t automatically update our image
        _fileURL = fileURL
        if NSImage.canInit(with: sender.draggingPasteboard()) {
            image = NSImage(pasteboard: sender.draggingPasteboard())
        } else {
            image = icon(for: fileURL)
        }

        delegate?.fileDropImageView(self, didReceiveDroppedFileURL: fileURL)
        return true
    }
}
