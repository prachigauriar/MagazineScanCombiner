//
//  CombineScansOperation.swift
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

class CombineScansOperation: ConcurrentProgressReportingOperation {
    enum Error: ErrorType {
        case CouldNotOpenFileURL(NSURL)
        case CouldNotCreateOutputPDF(NSURL)
    }

    let frontPagesPDFURL: NSURL
    let reversedBackPagesPDFURL: NSURL
    let outputPDFURL: NSURL

    private(set) var error: Error?

    init(frontPagesPDFURL: NSURL, reversedBackPagesPDFURL: NSURL, outputPDFURL: NSURL) {
        self.frontPagesPDFURL = frontPagesPDFURL
        self.reversedBackPagesPDFURL = reversedBackPagesPDFURL
        self.outputPDFURL = outputPDFURL

        super.init()

        progress.cancellationHandler = { [unowned self] in
            self.cancel()
        }
    }


    override func start() {
        // If we’re finished or canceled, return immediately
        guard !finished && !cancelled else {
            return 
        }

        executing = true

        // However we exit, we want to mark ourselves as no longer executing
        defer { finished = true }

        // If we couldn’t open the front pages PDF, set our error, finish, and exit
        guard let frontPagesDocument = CGPDFDocumentCreateWithURL(frontPagesPDFURL) else {
            error = Error.CouldNotOpenFileURL(frontPagesPDFURL)
            return
        }

        // If we couldn’t open the reversed back pages PDF, set our error, finish, and exit
        guard let reversedBackPagesDocument = CGPDFDocumentCreateWithURL(reversedBackPagesPDFURL) else {
            error = Error.CouldNotOpenFileURL(reversedBackPagesPDFURL)
            return
        }

        // If we couldn’t create the output PDF context, set our error, finish, and exit
        guard let outputPDFContext = CGPDFContextCreateWithURL(outputPDFURL, nil, nil) else {
            error = Error.CouldNotCreateOutputPDF(outputPDFURL)
            return
        }

        let pageCount = CGPDFDocumentGetNumberOfPages(frontPagesDocument) + CGPDFDocumentGetNumberOfPages(reversedBackPagesDocument)
        progress.totalUnitCount = Int64(pageCount)

        var pageGenerator = ScannedPagesGenerator(frontPagesDocument: frontPagesDocument, reversedBackPagesDocument: reversedBackPagesDocument)
        while !cancelled, let page = pageGenerator.next() {
            // Start a new page in our output, get the contents of the page from our input, write that page to our output
            var mediaBox = CGPDFPageGetBoxRect(page, .MediaBox)
            CGContextBeginPage(outputPDFContext, &mediaBox)
            CGContextDrawPDFPage(outputPDFContext, page)
            CGContextEndPage(outputPDFContext)
            progress.completedUnitCount += 1
        }

        CGPDFContextClose(outputPDFContext)

        // If we were canceled, try to remove the output PDF, but don’t worry about it if we can’t
        if cancelled {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(outputPDFURL)
            } catch {
            }
        }
    }
}


private struct ScannedPagesGenerator: GeneratorType {
    var nextPageIsFront: Bool
    var frontPageGenerator: PDFDocumentPageGenerator
    var backPageGenerator: PDFDocumentPageGenerator

    init(frontPagesDocument: CGPDFDocument, reversedBackPagesDocument: CGPDFDocument) {
        nextPageIsFront = true
        let frontPageArray = Array(1 ..< (CGPDFDocumentGetNumberOfPages(frontPagesDocument) + 1))
        let backPageArray = Array((1 ..< (CGPDFDocumentGetNumberOfPages(reversedBackPagesDocument) + 1)).reverse())

        frontPageGenerator = PDFDocumentPageGenerator(document: frontPagesDocument, pages: frontPageArray)
        backPageGenerator = PDFDocumentPageGenerator(document: reversedBackPagesDocument, pages: backPageArray)
    }


    mutating func next() -> CGPDFPage? {
        let page: CGPDFPage?

        defer { nextPageIsFront = !nextPageIsFront }

        if nextPageIsFront {
            return frontPageGenerator.next() ?? backPageGenerator.next()
        } else {
            return backPageGenerator.next() ?? frontPageGenerator.next()
        }
    }
}


private struct PDFDocumentPageGenerator: GeneratorType {
    let document: CGPDFDocument
    var pageGenerator: IndexingGenerator<[Int]>

    init(document: CGPDFDocument, pages: [Int]) {
        self.document = document
        pageGenerator = pages.generate()
    }


    mutating func next() -> CGPDFPage? {
        guard let pageNumber = pageGenerator.next() else {
            return nil
        }

        return CGPDFDocumentGetPage(document, pageNumber)
    }
}
