//
//  main.swift
//  scancombine
//
//  Created by Prachi Gauriar on 7/5/2016.
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

import Foundation

// Global standard error stream
var standardErrorStream = StandardErrorStream()


/// Prints command-line usage and exits with status 1.
func printUsageAndExit() -> Never  {
    print("Usage: \(ProcessInfo.processInfo.processName) frontPagesPDF reversedBackPagesPDF outputPDF", to: &standardErrorStream)
    exit(1)
}


/// Converts the specified file path into a file URL and returns it if its reachable.
/// - parameter path: The file path to convert into a URL. If relative, the returned URL is
///     relative to the process’s current working directory. If the path begins with a “~” or
///     “~*user*”, the tilde is expanded before converting it into a URL.
/// - returns: A file URL for the specified file path if it is reachable; `nil` otherwise.
func validatedFileURL(withPath path: String) -> URL? {
    let url = URL(fileURLWithPath: path.expandingTildeInPath)

    guard let isReachable = try? url.checkResourceIsReachable() , isReachable else {
        return nil
    }

    return url
}


/// Parses the processes’s command-line arguments and returns them in a tuple. If an error
/// occurs while parsing command-line arguments, prints an error message and exits.
//
/// - returns: A tuple containing the command-line arguments as URLs.
func parseCommandLineArguments() -> (frontPagesFileURL: URL, reversedBackPagesFileURL: URL, outputFileURL: URL) {
    let userArguments = ProcessInfo.processInfo.userArguments
    var standardErrorStream = StandardErrorStream()

    guard userArguments.count == 3 else {
        printUsageAndExit()
    }

    let frontPagesPath = userArguments[0]
    guard let frontPagesFileURL = validatedFileURL(withPath: frontPagesPath) else {
        print("Could not open front pages PDF \(frontPagesPath)", to: &standardErrorStream)
        exit(2)
    }

    let reversedBackPagesPath = userArguments[1]
    guard let reversedBackPagesFileURL = validatedFileURL(withPath: reversedBackPagesPath) else {
        print("Could not open reversed back pages PDF \(reversedBackPagesPath)", to: &standardErrorStream)
        exit(2)
    }

    let outputFileURL = URL(fileURLWithPath: userArguments[2].expandingTildeInPath)

    return (frontPagesFileURL, reversedBackPagesFileURL, outputFileURL)
}

// Parse the command-line arguments
let (frontPagesPDFURL, reversedBackPagesPDFURL, outputPDFURL) = parseCommandLineArguments()

// Create and start a combine scans operation with those arguments
let operation = CombineScansOperation(frontPagesPDFURL: frontPagesPDFURL, reversedBackPagesPDFURL: reversedBackPagesPDFURL, outputPDFURL: outputPDFURL)
operation.start()

// When the operation is done, if it doesn’t have an error, everything succeeded
guard let error = operation.error else {
    print("Successfully combined PDFs and saved output to \(outputPDFURL.path.abbreviatingWithTildeInPath).")
    exit(0)
}

// Otherwise, print an appropriate error message
switch error {
case let .couldNotOpenFileURL(fileURL):
    print("Could not open input PDF \(fileURL.path.abbreviatingWithTildeInPath).", to: &standardErrorStream)
case let  .couldNotCreateOutputPDF(fileURL):
    print("Could not create output PDF \(fileURL.path.abbreviatingWithTildeInPath).", to: &standardErrorStream)
}
