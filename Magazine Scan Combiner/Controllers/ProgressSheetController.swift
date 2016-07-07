//
//  ProgressSheetController.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/4/2016.
//  Copyright © 2016 Quantum Lens Cap. All rights reserved.
//

import Cocoa

class ProgressSheetController: NSWindowController {
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet var messageLabel: NSTextField!
    @IBOutlet var cancelButton: NSButton!

    var localizedMesageKey: String?

    var progress: NSProgress? {
        didSet {
            if let progress = progress {
                progressObserver = KeyValueObserver(object: progress, keyPath: "completedUnitCount", observeBlock: { [unowned self] (progress) in
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.updateWithProgressChange()
                    }
                })
            } else {
                progressObserver = nil
            }
        }
    }

    private var progressObserver: KeyValueObserver<NSProgress>?


    override var windowNibName: String? {
        return "ProgressSheetWindow"
    }


    override func windowDidLoad() {
        super.windowDidLoad()
        messageLabel.stringValue = ""
    }


    func updateWithProgressChange() {
        guard let progress = progress, localizedMessageKey = localizedMesageKey else {
            return
        }

        let formatString = NSLocalizedString(localizedMessageKey, comment: "")
        let message = String.localizedStringWithFormat(formatString, progress.completedUnitCount + 1, progress.totalUnitCount)

        messageLabel.stringValue = message
        progressIndicator.doubleValue = 100 * progress.fractionCompleted
    }


    @IBAction func cancel(sender: NSButton) {
        if let progress = progress  {
            progress.cancel()
        }
    }
}
