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
        print("Could not open front pages PDF \(frontPagesPath)", toStream: &standardErrorStream)
        exit(2)
    }

    let reversedBackPagesPath = userArguments[1]
    guard let reversedBackPagesFileURL = validatedFileURLWithPath(reversedBackPagesPath) else {
        print("Could not open reversed back pages PDF \(reversedBackPagesPath)", toStream: &standardErrorStream)
        exit(2)
    }

    let outputFileURL = NSURL(fileURLWithPath: userArguments[2].stringByExpandingTildeInPath)

    return (frontPagesFileURL, reversedBackPagesFileURL, outputFileURL)
}


let (frontPagesPDFURL, reversedBackPagesPDFURL, outputPDFURL) = parseCommandLineArguments()
let operation = CombineScansOperation(frontPagesPDFURL: frontPagesPDFURL, reversedBackPagesPDFURL: reversedBackPagesPDFURL, outputPDFURL: outputPDFURL)
operation.start()

guard let error = operation.error else {
    print("Successfully combined PDFs and saved output to \(outputPDFURL.path!.stringByAbbreviatingWithTildeInPath).")
    exit(0)
}

switch error {
case let .CouldNotOpenFileURL(fileURL):
    print("Could not open input PDF \(fileURL.path!.stringByAbbreviatingWithTildeInPath).", toStream: &standardErrorStream)
case let  .CouldNotCreateOutputPDF(fileURL):
    print("Could not create output PDF \(fileURL.path!.stringByAbbreviatingWithTildeInPath).", toStream: &standardErrorStream)
}
