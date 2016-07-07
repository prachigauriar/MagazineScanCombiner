//
//  ProgressSheetController.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/4/2016.
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

class ProgressSheetController: NSWindowController {
    // MARK: - Outlets

    @IBOutlet var messageLabel: NSTextField!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet var cancelButton: NSButton!

    
    // MARK: - Properties for setting the progress message

    var localizedProgressMesageKey: String?


    // MARK: - Progress properties

    private var needsProgressUpdate: Bool = false
    private let progressUpdateInterval: NSTimeInterval = 1 / 60
    private var progressObserver: KeyValueObserver<NSProgress>?

    private var progressUpdateTimer: NSTimer? {
        willSet {
            // Invalidate any previous timers whenever the update timer is about to be set
            progressUpdateTimer?.invalidate()
        }
    }

    var progress: NSProgress? {
        didSet {
            if let progress = progress {
                // Begin observing changes to progress
                progressObserver = KeyValueObserver(object: progress, keyPath: "completedUnitCount") { [unowned self] _ in
                    self.needsProgressUpdate = true
                }

                // Schedule the update timer
                let updateTimer = NSTimer.init(timeInterval: progressUpdateInterval,
                                               target: self,
                                               selector: #selector(updateProgressWithTimer(_:)),
                                               userInfo: nil,
                                               repeats: true)
                self.progressUpdateTimer = updateTimer
                NSRunLoop.mainRunLoop().addTimer(updateTimer, forMode: NSRunLoopCommonModes)
            } else {
                // Stop observing progress
                progressObserver = nil

                // Get rid of our update timer
                progressUpdateTimer = nil
            }
        }
    }


    // MARK: - NSWindowController subclass overrides

    override var windowNibName: String? {
        return "ProgressSheetWindow"
    }


    override func windowDidLoad() {
        super.windowDidLoad()
        messageLabel.stringValue = ""
    }


    // MARK: - Action methods

    @IBAction func cancel(sender: NSButton) {
        if let progress = progress  {
            progress.cancel()
        }
    }


    // MARK: - Updating the progress UI

    func updateProgressWithTimer(timer: NSTimer) {
        guard needsProgressUpdate,
            let window = window where window.visible,
            let localizedProgressMessageKey = localizedProgressMesageKey,
            let progress = progress where progress.completedUnitCount < progress.totalUnitCount else {
                return
        }

        let formatString = NSLocalizedString(localizedProgressMessageKey, comment: "")
        let message = String.localizedStringWithFormat(formatString, progress.completedUnitCount + 1, progress.totalUnitCount)

        messageLabel.stringValue = message
        progressIndicator.doubleValue = 100 * progress.fractionCompleted
    }
}
