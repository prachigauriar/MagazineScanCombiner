//
//  AppDelegate.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/3/2016.
//  Copyright © 2016 Quantum Lens Cap. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var mainWindowController: ScanCombinerWindowController!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        mainWindowController.showWindow(nil)
    }
}

