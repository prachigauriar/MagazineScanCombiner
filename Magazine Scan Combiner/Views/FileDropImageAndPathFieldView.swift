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


protocol FileDropImageAndPathFieldViewDelegate {
    func fileDropImageAndPathFieldView(view: FileDropImageAndPathFieldView, shouldAcceptDraggedFileURL fileURL: NSURL) -> Bool
    func fileDropImageAndPathFieldView(view: FileDropImageAndPathFieldView, didReceiveDroppedFileURL fileURL: NSURL)
}


@IBDesignable class FileDropImageAndPathFieldView: NSView, FileDropImageViewDelegate {
    private let fileDropImageView: FileDropImageView
    private let pathField: NSTextField

    @IBInspectable var pathPlaceholderString: String? {
        get {
            return pathField.placeholderString
        }

        set {
            pathField.placeholderString = newValue
        }
    }

    var delegate: FileDropImageAndPathFieldViewDelegate?

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
        fileDropImageView.imageFrameStyle = .GrayBezel
        fileDropImageView.imageScaling = .ScaleProportionallyUpOrDown
        fileDropImageView.delegate = self

        pathField.translatesAutoresizingMaskIntoConstraints = false
        pathField.editable = false
        pathField.selectable = true
        pathField.usesSingleLineMode = true
        pathField.bezeled = true
        pathField.bezelStyle = .SquareBezel
        pathField.cell?.scrollable = true
        pathField.setContentCompressionResistancePriority(250, forOrientation: .Horizontal)

        addSubview(fileDropImageView)
        addSubview(pathField)

        fileDropImageView.leadingAnchor.constraintEqualToAnchor(self.leadingAnchor, constant: 3).active = true
        fileDropImageView.trailingAnchor.constraintEqualToAnchor(self.trailingAnchor, constant: -3).active = true
        fileDropImageView.topAnchor.constraintEqualToAnchor(self.topAnchor, constant: 3).active = true

        pathField.leadingAnchor.constraintEqualToAnchor(fileDropImageView.leadingAnchor).active = true
        pathField.trailingAnchor.constraintEqualToAnchor(fileDropImageView.trailingAnchor).active = true
        pathField.topAnchor.constraintEqualToAnchor(fileDropImageView.bottomAnchor, constant: 8).active = true
        pathField.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor).active = true
    }


    // MARK: - File Drop Image View delegate

    func fileDropImageView(imageView: FileDropImageView, shouldAcceptDraggedFileURL fileURL: NSURL) -> Bool {
        return delegate?.fileDropImageAndPathFieldView(self, shouldAcceptDraggedFileURL: fileURL) ?? false
    }


    func fileDropImageView(imageView: FileDropImageView, didReceiveDroppedFileURL fileURL: NSURL) {
        delegate?.fileDropImageAndPathFieldView(self, didReceiveDroppedFileURL: fileURL)

        guard let path: NSString = fileURL.path else {
            return
        }

        pathField.stringValue = path.stringByAbbreviatingWithTildeInPath
    }
}
