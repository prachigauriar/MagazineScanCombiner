//
//  FileDropImageAndPathFieldView.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/8/2016.
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


/// The `FileDropImageAndPathFieldViewDelegate` protocol allows users of
/// `FileDropImageAndPathFieldViews` to be notified when a file has been dropped on the view as well
/// as controlling which file URLs are acceptable.
protocol FileDropImageAndPathFieldViewDelegate {
    /// Returns whether the  view should accept a drop for the specified file URL. This method can be
    /// used to allow only certain files, e.g., only files with a given type or file extension, or files
    /// located in a certain area of the file system. For example, to only accept spreadsheets, your
    /// implementation may look like:
    ///
    /// ```
    /// do {
    ///     var resourceValue: AnyObject? = nil
    ///     try fileURL.getResourceValue(&resourceValue, forKey: NSURLTypeIdentifierKey)
    ///     guard let fileType = resourceValue as? String else {
    ///         return false
    ///     }
    ///
    ///     return UTTypeConformsTo(fileType, kUTTypeSpreadsheet)
    /// } catch {
    ///     return false
    /// }
    /// ```
    ///
    /// - parameter view: The file drop image and path field view.
    /// - parameter fileURL: A file URL for the file being dragged onto the view.
    /// - returns: Whether the view should accept the file.
    func fileDropImageAndPathFieldView(_ view: FileDropImageAndPathFieldView, shouldAcceptDraggedFileURL fileURL: URL) -> Bool

    /// Notifies the receiver that the specified file URL has been dropped on the file drop image and path field view.
    ///
    /// - parameter view: The file drop image and path field view.
    /// - parameter fileURL: The file URL for the file that was dropped.
    func fileDropImageAndPathFieldView(_ view: FileDropImageAndPathFieldView, didReceiveDroppedFileURL fileURL: URL)
}


/// `FileDropImageAndPathFieldView` instances make it easy to receive file URLs from the user via a
/// drag-and-drop interface and display the file’s icon and path. When a file is dragged onto the
/// view’s drop area, the view asks its delegate whether the file URL is an acceptable type. If it
/// is and the file is dropped onto the instance, the view will update its image to the file’s icon
/// or a thumbnail of the file’s contents if the file is an image. It will also update the contents
/// of its path field to show the dropped file’s path. It will then notify the delegate of the dropped
/// file’s URL.
@IBDesignable class FileDropImageAndPathFieldView : NSView, FileDropImageViewDelegate {
    /// The file drop image view the instance uses to handle file drops
    private let fileDropImageView: FileDropImageView

    /// The text field the instance uses to display file paths
    private let pathField: NSTextField

    /// The placeholder string used in the instance’s path field
    @IBInspectable var pathFieldPlaceholderString: String? {
        get { return pathField.placeholderString }
        set { pathField.placeholderString = newValue }
    }

    /// The instance’s delegate
    var delegate: FileDropImageAndPathFieldViewDelegate?

    private var _fileURL: URL? {
        didSet {
            guard let path = _fileURL?.path else {
                return
            }

            pathField.stringValue = path.abbreviatingWithTildeInPath
        }
    }

    /// The instance’s file URL
    var fileURL: URL? {
        get { return _fileURL }
        set {
            _fileURL = newValue
            fileDropImageView.fileURL = newValue
        }
    }

    override init(frame: CGRect) {
        fileDropImageView = FileDropImageView()
        pathField = NSTextField()
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        initializeSubviews()
    }


    required init?(coder: NSCoder) {
        fileDropImageView = FileDropImageView()
        pathField = NSTextField()
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
        initializeSubviews()
    }


    private func initializeSubviews() {
        fileDropImageView.translatesAutoresizingMaskIntoConstraints = false
        fileDropImageView.imageFrameStyle = .grayBezel
        fileDropImageView.imageScaling = .scaleProportionallyUpOrDown
        fileDropImageView.delegate = self

        pathField.translatesAutoresizingMaskIntoConstraints = false
        pathField.isEditable = false
        pathField.isSelectable = true
        pathField.usesSingleLineMode = true
        pathField.isBezeled = true
        pathField.bezelStyle = .squareBezel
        pathField.cell?.isScrollable = true
        pathField.setContentCompressionResistancePriority(250, for: .horizontal)

        addSubview(fileDropImageView)
        addSubview(pathField)

        fileDropImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 3).isActive = true
        fileDropImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -3).isActive = true
        fileDropImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 3).isActive = true

        pathField.leadingAnchor.constraint(equalTo: fileDropImageView.leadingAnchor).isActive = true
        pathField.trailingAnchor.constraint(equalTo: fileDropImageView.trailingAnchor).isActive = true
        pathField.topAnchor.constraint(equalTo: fileDropImageView.bottomAnchor, constant: 8).isActive = true
        pathField.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }


    // MARK: - File Drop Image View delegate

    func fileDropImageView(_ imageView: FileDropImageView, shouldAcceptDraggedFileURL fileURL: URL) -> Bool {
        return delegate?.fileDropImageAndPathFieldView(self, shouldAcceptDraggedFileURL: fileURL) ?? false
    }


    func fileDropImageView(_ imageView: FileDropImageView, didReceiveDroppedFileURL fileURL: URL) {
        _fileURL = fileURL
        delegate?.fileDropImageAndPathFieldView(self, didReceiveDroppedFileURL: fileURL)
    }
}
