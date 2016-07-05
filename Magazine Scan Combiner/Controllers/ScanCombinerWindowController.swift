//
//  ScanCombinerWindowController.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/3/2016.
//  Copyright © 2016 Quantum Lens Cap. All rights reserved.
//

import Cocoa


class ScanCombinerWindowController: NSWindowController, FileDropImageViewDelegate {
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


    override var windowNibName: String? {
        return "ScanCombinerWindow"
    }


    override func windowDidLoad() {
        super.windowDidLoad()
        frontPagesFileDropImageView.delegate = self
        reversedBackPagesFileDropImageView.delegate = self
        updateCombinePDFsButtonEnabled()
    }


    // MARK: - Action Methods

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

        let scanCombiner = ScanCombiner()
        do {
            let progress = try scanCombiner.combineScansWithFrontPagesPDFURL(frontPagesURL,
                                                                             reversedBackPagesPDFURL: reversedBackPagesURL,
                                                                             outputURL: outputURL)

            progress.addObserver(self, forKeyPath: "fractionCompleted", options: .Initial, context: nil)

            self.window?.beginSheet(progressSheetController.window!, completionHandler: { _ in
                progress.removeObserver(self, forKeyPath: "fractionCompleted")
                NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([outputURL])
            })
        } catch ScanCombiner.Error.CouldNotOpenInputPDF {
            print("Could not open input PDF")
        } catch ScanCombiner.Error.CouldNotCreateOutputPDF {
            print("Could not create output PDF")
        } catch {
            print("Something else went wrong")
        }
    }


    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let progress = object as? NSProgress, let progressSheet = progressSheetController.window else {
            return
        }

        NSOperationQueue.mainQueue().addOperationWithBlock { [unowned self] in
            if progress.completedUnitCount < progress.totalUnitCount {
                self.progressSheetController.updateWithProgress(progress, localizedMessageKey: "CombineProgress.Format")
            } else {
                self.window?.endSheet(progressSheet)
            }
        }
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
