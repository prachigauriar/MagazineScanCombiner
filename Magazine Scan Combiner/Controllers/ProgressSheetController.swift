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

    override var windowNibName: String? {
        return "ProgressSheetWindow"
    }


    func updateWithProgress(progress: NSProgress, localizedMessageKey: String) {
        let formatString = NSLocalizedString(localizedMessageKey, comment: "")
        let message = String.localizedStringWithFormat(formatString, progress.completedUnitCount + 1, progress.totalUnitCount)

        self.messageLabel.stringValue = message
        self.progressIndicator.doubleValue = 100 * progress.fractionCompleted
    }
}
