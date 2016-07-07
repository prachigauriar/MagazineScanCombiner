//
//  ScanCombinerWindowController.swift
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


class ScanCombinerWindowController: NSWindowController, FileDropImageViewDelegate {
    // MARK: - User Interface properties

    @IBOutlet var frontPagesFileDropImageView: FileDropImageView!
    @IBOutlet var frontPagesFilePathField: NSTextField!
    @IBOutlet var reversedBackPagesFileDropImageView: FileDropImageView!
    @IBOutlet var reversedBackPagesFilePathField: NSTextField!
    @IBOutlet var combinePDFsButton: NSButton!

    private let progressSheetController = ProgressSheetController()

    var frontPagesURL: NSURL? {
        didSet {
            if let URL = frontPagesURL {
                updateTextField(frontPagesFilePathField, withURL: URL)
            }

            updateCombinePDFsButtonEnabled()
        }
    }


    var reversedBackPagesURL: NSURL? {
        didSet {
            if let URL = reversedBackPagesURL {
                updateTextField(reversedBackPagesFilePathField, withURL: URL)
            }

            updateCombinePDFsButtonEnabled()
        }
    }

    // MARK: - Model properties

    lazy var operationQueue: NSOperationQueue = {
        let operationQueue = NSOperationQueue()
        operationQueue.name = "\(self.dynamicType).\(unsafeAddressOf(self))"
        return operationQueue
    }()


    // MARK: - NSWindowController subclass overrides

    override var windowNibName: String? {
        return "ScanCombinerWindow"
    }


    override func windowDidLoad() {
        super.windowDidLoad()
        frontPagesFileDropImageView.delegate = self
        reversedBackPagesFileDropImageView.delegate = self
        updateCombinePDFsButtonEnabled()
    }


    // MARK: - Action methods

    @IBAction func combinePDFs(sender: NSButton) {
        guard let directory = frontPagesURL?.URLByDeletingLastPathComponent else {
            NSBeep()
            return
        }

        let savePanel = NSSavePanel()
        savePanel.directoryURL = directory
        savePanel.allowedFileTypes = ["pdf"]
        savePanel.canSelectHiddenExtension = true

        savePanel.beginSheetModalForWindow(self.window!) { [unowned self] result in
            guard result == NSFileHandlingPanelOKButton,
                let outputURL = savePanel.URL else {
                    return
            }

            self.beginCombiningPDFsWithOutputURL(outputURL)
        }
    }


    private func beginCombiningPDFsWithOutputURL(outputURL: NSURL) {
        guard let frontPagesURL = frontPagesURL, let reversedBackPagesURL = reversedBackPagesURL else {
            return
        }

        // Create the combine scan operation with our input and output PDF URLs
        let operation = CombineScansOperation(frontPagesPDFURL: frontPagesURL, reversedBackPagesPDFURL: reversedBackPagesURL, outputPDFURL: outputURL)

        // Set up a Key-Value Observer to observe the completedUnitCount
        self.progressSheetController.progress = operation.progress
        self.progressSheetController.localizedMesageKey = "CombineProgress.Format"

        // Add a completion block that hides the progress sheet when the operation finishes
        operation.completionBlock = { [weak self] in
            self?.progressSheetController.progress = nil

            NSOperationQueue.mainQueue().addOperationWithBlock { [weak self] in
                guard let progressSheet = self?.progressSheetController.window! else {
                    return
                }

                self?.window?.endSheet(progressSheet)
            }
        }

        // Begin showing the progress sheet. On dismiss, either show an error or show the resultant PDF file
        self.window?.beginSheet(self.progressSheetController.window!, completionHandler: { [unowned self] _ in
            if let error = operation.error {
                // If there was an error, show an alert to the user
                self.showAlertForError(error)
            } else if !operation.cancelled {
                // Otherwise show the resultant PDF in the Finder if it wasn’t canceled
                NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([outputURL])
            }
        })

        self.operationQueue.addOperation(operation)
    }


    private func showAlertForError(error: CombineScansOperation.Error) {
        let alert = NSAlert()
        alert.addButtonWithTitle(NSLocalizedString("OK", comment: "OK button title"))

        switch error {
        case let .CouldNotOpenFileURL(fileURL):
            updateAlert(alert, withErrorLocalizedKey: "CouldNotOpenFile", fileURL: fileURL)
        case let  .CouldNotCreateOutputPDF(fileURL):
            updateAlert(alert, withErrorLocalizedKey: "CouldNotCreateFile", fileURL: fileURL)
        }

        alert.beginSheetModalForWindow(self.window!, completionHandler: nil)
    }


    private func updateAlert(alert: NSAlert, withErrorLocalizedKey key: String, fileURL: NSURL) {
        alert.messageText = NSLocalizedString("Error.\(key).MessageText", comment: "")
        alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("Error.\(key).InformativeText.Format", comment: ""),
                                                                 fileURL.path!.stringByAbbreviatingWithTildeInPath)
    }


    // MARK: - File Drop Image View Delegate

    func fileDropImageView(imageView: FileDropImageView, shouldAcceptDraggedFileURL fileURL: NSURL) -> Bool {
        return fileURL.pathExtension?.caseInsensitiveCompare("pdf") == .OrderedSame
    }


    func fileDropImageView(imageView: FileDropImageView, didReceiveDroppedFileURL fileURL: NSURL) {
        if imageView == frontPagesFileDropImageView {
            self.frontPagesURL = fileURL
        } else {
            self.reversedBackPagesURL = fileURL
        }
    }


    // MARK: - Updating the UI

    private func updateTextField(field: NSTextField, withURL fileURL: NSURL) {
        guard let path: NSString = fileURL.path else {
            return
        }

        field.stringValue = path.stringByAbbreviatingWithTildeInPath
    }


    private func updateCombinePDFsButtonEnabled() {
        combinePDFsButton.enabled = frontPagesURL != nil && reversedBackPagesURL != nil
    }
}
