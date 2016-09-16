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

class ProgressSheetController : NSWindowController {
    // MARK: - Outlets

    @IBOutlet var messageLabel: NSTextField!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet var cancelButton: NSButton!

    
    // MARK: - Properties for setting the progress message

    var localizedProgressMesageKey: String?


    // MARK: - Progress properties

    private var progressObserver: KeyValueObserver<Progress>?

    var progress: Progress? {
        didSet {
            if let progress = progress {
                // Begin observing changes to progress
                progressObserver = KeyValueObserver(object: progress, keyPath: #keyPath(Progress.completedUnitCount)) { [unowned self] _ in
                    self.needsProgressUpdate = true
                }
            } else {
                // Stop observing progress
                progressObserver = nil
            }
        }
    }

    private let progressUpdateInterval: TimeInterval = 1 / 60
    private var progressUpdateTimer: Timer?
    private var needsProgressUpdate: Bool = false {
        didSet {
            if !(progressUpdateTimer?.isValid ?? false) {
                // Schedule the update timer
                let updateTimer = Timer(timeInterval: progressUpdateInterval,
                                        target: self,
                                        selector: #selector(updateProgress(with:)),
                                        userInfo: nil,
                                        repeats: false)
                progressUpdateTimer = updateTimer
                RunLoop.main.add(updateTimer, forMode: RunLoopMode.commonModes)
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

    @IBAction func cancel(_ sender: NSButton) {
        if let progress = progress  {
            progress.cancel()
        }
    }


    // MARK: - Updating the progress UI

    func updateProgress(with timer: Timer) {
        progressUpdateTimer = nil
        updateProgress()
    }


    func updateProgress() {
        guard needsProgressUpdate,
            let window = window,
            window.isVisible,
            let progress = progress,
            progress.completedUnitCount < progress.totalUnitCount else {
                return
        }
        
        needsProgressUpdate = false
        progressIndicator.doubleValue = 100 * progress.fractionCompleted

        if let localizedProgressMessageKey = localizedProgressMesageKey {
            let formatString = NSLocalizedString(localizedProgressMessageKey, comment: "")
            let message = String.localizedStringWithFormat(formatString, progress.completedUnitCount + 1, progress.totalUnitCount)
            messageLabel.stringValue = message
        }
    }
}
