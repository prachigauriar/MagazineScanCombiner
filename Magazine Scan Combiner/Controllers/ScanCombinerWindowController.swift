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


class ScanCombinerWindowController : NSWindowController, FileDropImageAndPathFieldViewDelegate {
    // MARK: - Outlets and UI-related properties

    @IBOutlet var frontPagesDropView: FileDropImageAndPathFieldView!
    @IBOutlet var reversedBackPagesDropView: FileDropImageAndPathFieldView!
    @IBOutlet var combinePDFsButton: NSButton!


    // MARK: - User input properties

    var frontPagesURL: URL? {
        didSet {
            updateCombinePDFsButtonEnabledState()
        }
    }


    var reversedBackPagesURL: URL? {
        didSet {
            updateCombinePDFsButtonEnabledState()
        }
    }


    // MARK: - Concurrency

    lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "\(type(of: self)).\(Unmanaged.passUnretained(self).toOpaque())"
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
        updateCombinePDFsButtonEnabledState()
    }


    // MARK: - Action methods

    @IBAction func combinePDFs(_ sender: NSButton) {
        guard let directoryURL = frontPagesURL?.deletingLastPathComponent() else {
            NSBeep()
            return
        }

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = NSLocalizedString("ScanCombinerWindowController.DefaultOutputFilename",
                                                           comment: "Default filename for the output PDF")
        savePanel.directoryURL = directoryURL
        savePanel.allowedFileTypes = [kUTTypePDF as String]
        savePanel.canSelectHiddenExtension = true

        savePanel.beginSheetModal(for: self.window!) { [unowned self] result in
            guard result == NSFileHandlingPanelOKButton,
                let outputURL = savePanel.url else {
                    return
            }

            self.beginCombiningPDFs(withOutputURL: outputURL)
        }
    }


    private func beginCombiningPDFs(withOutputURL outputURL: URL) {
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

            OperationQueue.main.addOperation { [weak self] in
                guard let progressSheet = progressSheetController.window else {
                    return
                }

                self?.window?.endSheet(progressSheet)
            }
        }

        // Begin showing the progress sheet. On dismiss, either show an error or show the resultant PDF file
        self.window?.beginSheet(progressSheetController.window!, completionHandler: { [unowned self] _ in
            if let error = operation.errorBox?.error {
                // If there was an error, show an alert to the user
                self.showAlert(for: error)
            } else if !operation.isCancelled {
                // Otherwise show the resultant PDF in the Finder if it wasn’t canceled
                NSWorkspace.shared().activateFileViewerSelecting([outputURL])
            }
        })

        self.operationQueue.addOperation(operation)
    }


    // MARK: - Updating the UI based on user input

    private func updateCombinePDFsButtonEnabledState() {
        combinePDFsButton.isEnabled = frontPagesURL != nil && reversedBackPagesURL != nil
    }


    // MARK: - Showing alerts

    private func showAlert(for error: CombineScansError) {
        let alert = NSAlert()
        alert.addButton(withTitle: NSLocalizedString("OK", comment: "OK button title"))

        switch error {
        case let .couldNotOpenFileURL(fileURL):
            updateAlert(alert, withErrorLocalizedKey: "CouldNotOpenFile", fileURL: fileURL)
        case let  .couldNotCreateOutputPDF(fileURL):
            updateAlert(alert, withErrorLocalizedKey: "CouldNotCreateFile", fileURL: fileURL)
        }

        alert.beginSheetModal(for: self.window!, completionHandler: nil)
    }


    private func updateAlert(_ alert: NSAlert, withErrorLocalizedKey key: String, fileURL: URL) {
        alert.messageText = NSLocalizedString("Error.\(key).MessageText", comment: "")
        alert.informativeText = String.localizedStringWithFormat(NSLocalizedString("Error.\(key).InformativeText.Format", comment: ""),
                                                                 fileURL.path.abbreviatingWithTildeInPath)
    }


    // MARK: - File Drop Image and Path Field View delegate

    func fileDropImageAndPathFieldView(_ view: FileDropImageAndPathFieldView, shouldAcceptDraggedFileURL fileURL: URL) -> Bool {
        do {
            var resourceValue: AnyObject? = nil
            try (fileURL as NSURL).getResourceValue(&resourceValue, forKey: URLResourceKey.typeIdentifierKey)
            guard let fileType = resourceValue as? String else {
                return false
            }

            return UTTypeConformsTo(fileType as CFString, kUTTypePDF)
        } catch {
            return false
        }
    }


    func fileDropImageAndPathFieldView(_ view: FileDropImageAndPathFieldView, didReceiveDroppedFileURL fileURL: URL) {
        if view == frontPagesDropView {
            self.frontPagesURL = fileURL
        } else {
            self.reversedBackPagesURL = fileURL
        }
    }
}
