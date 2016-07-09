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


class ScanCombinerWindowController: NSWindowController, FileDropImageAndPathFieldViewDelegate {
    // MARK: - Outlets and UI-related properties

    @IBOutlet var frontPagesDropView: FileDropImageAndPathFieldView!
    @IBOutlet var reversedBackPagesDropView: FileDropImageAndPathFieldView!
    @IBOutlet var combinePDFsButton: NSButton!


    // MARK: - User input properties

    var frontPagesURL: NSURL? {
        didSet {
            updateCombinePDFsButtonEnabled()
        }
    }


    var reversedBackPagesURL: NSURL? {
        didSet {
            updateCombinePDFsButtonEnabled()
        }
    }


    // MARK: - Concurrency

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
        frontPagesDropView.delegate = self
        reversedBackPagesDropView.delegate = self
        updateCombinePDFsButtonEnabled()
    }


    // MARK: - Action methods

    @IBAction func combinePDFs(sender: NSButton) {
        guard let directoryURL = frontPagesURL?.URLByDeletingLastPathComponent else {
            NSBeep()
            return
        }

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = NSLocalizedString("ScanCombinerWindowController.DefaultOutputFilename",
                                                           comment: "Default filename for the output PDF")
        savePanel.directoryURL = directoryURL
        savePanel.allowedFileTypes = [kUTTypePDF as String]
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

        // Set up a progress sheet controller so we can show a progress sheet
        let progressSheetController = ProgressSheetController()
        progressSheetController.progress = operation.progress
        progressSheetController.localizedProgressMesageKey = "CombineProgress.Format"

        // Add a completion block that hides the progress sheet when the operation finishes
        operation.completionBlock = { [weak self] in
            progressSheetController.progress = nil

            NSOperationQueue.mainQueue().addOperationWithBlock { [weak self] in
                guard let progressSheet = progressSheetController.window else {
                    return
                }

                self?.window?.endSheet(progressSheet)
            }
        }

        // Begin showing the progress sheet. On dismiss, either show an error or show the resultant PDF file
        self.window?.beginSheet(progressSheetController.window!, completionHandler: { [unowned self] _ in
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


    // MARK: - Updating the UI based on user input

    private func updateCombinePDFsButtonEnabled() {
        combinePDFsButton.enabled = frontPagesURL != nil && reversedBackPagesURL != nil
    }


    // MARK: - Showing alerts

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


    // MARK: - File Drop Image and Path Field View delegate

    func fileDropImageAndPathFieldView(view: FileDropImageAndPathFieldView, shouldAcceptDraggedFileURL fileURL: NSURL) -> Bool {
        do {
            var resourceValue: AnyObject? = nil
            try fileURL.getResourceValue(&resourceValue, forKey: NSURLTypeIdentifierKey)
            guard let fileType = resourceValue as? String else {
                return false
            }

            return UTTypeConformsTo(fileType, kUTTypePDF)
        } catch {
            return false
        }
    }


    func fileDropImageAndPathFieldView(view: FileDropImageAndPathFieldView, didReceiveDroppedFileURL fileURL: NSURL) {
        if view == frontPagesDropView {
            self.frontPagesURL = fileURL
        } else {
            self.reversedBackPagesURL = fileURL
        }
    }
}
