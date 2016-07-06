//
//  main.swift
//  scancombine
//
//  Created by Prachi Gauriar on 7/5/2016.
//  Copyright © 2016 Quantum Lens Cap. All rights reserved.
//

import Foundation


 @noreturn func printUsageAndExit() {
    print("\(NSProcessInfo.processInfo().processName) frontPagesPDF reversedBackPagesPDF outputPDF", toStream: &standardErrorStream)
    exit(1)
}


func validatedFileURLWithPath(path: String) -> NSURL? {
    let URL = NSURL(fileURLWithPath: path.stringByExpandingTildeInPath)
    return URL.checkResourceIsReachableAndReturnError(nil) ? URL : nil
}


func parseCommandLineArguments() -> (frontPagesFileURL: NSURL, reversedBackPagesFileURL: NSURL, outputFileURL: NSURL) {
    let userArguments = NSProcessInfo.processInfo().userArguments
    guard userArguments.count == 3 else {
        printUsageAndExit()
    }

    let frontPagesPath = userArguments[0]
    guard let frontPagesFileURL = validatedFileURLWithPath(frontPagesPath) else {
        print("Unreachable front pages PDF \(frontPagesPath)", toStream: &standardErrorStream)
        exit(2)
    }

    let reversedBackPagesPath = userArguments[1]
    guard let reversedBackPagesFileURL = validatedFileURLWithPath(reversedBackPagesPath) else {
        print("Unreachable reversed front pages PDF \(reversedBackPagesPath)", toStream: &standardErrorStream)
        exit(2)
    }

    let outputFileURL = NSURL(fileURLWithPath: userArguments[2].stringByExpandingTildeInPath)

    return (frontPagesFileURL, reversedBackPagesFileURL, outputFileURL)
}


let commandLineArguments = parseCommandLineArguments()
let scanCombiner = ScanCombiner()

do {
    let progress = try scanCombiner.combineScansWithFrontPagesPDFURL(commandLineArguments.frontPagesFileURL,
                                                                     reversedBackPagesPDFURL: commandLineArguments.reversedBackPagesFileURL,
                                                                     outputURL: commandLineArguments.outputFileURL)

    scanCombiner.operationQueue.waitUntilAllOperationsAreFinished()
} catch ScanCombiner.Error.CouldNotOpenInputPDF {
    print("Could not open input PDF")
} catch ScanCombiner.Error.CouldNotCreateOutputPDF {
    print("Could not create output PDF")
} catch {
    print("Something else went wrong")
}
