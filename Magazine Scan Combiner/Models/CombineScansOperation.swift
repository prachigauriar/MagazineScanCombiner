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


/// `CombineScansOperation` is an `NSOperation` subclass that combines the pages of two PDFs into a
/// single new PDF. `CombineScansOperations` are meant to run concurrently in an operation queue,
/// although they can be run synchronously by simply invoking an instance’s `start` method.
///
/// ## Page Order in the Output PDF
///
/// The two input PDFs are combined in a peculiar way: the pages of the second PDF are first
/// reversed, and then interleaved with the pages of the first PDF. For example, suppose the first
/// PDF has pages *P1*, *P2*, …, *Pm*, and the second PDF has pages *Q1*, *Q2*, …, *Qn*. Then the
/// output PDF will have the pages *P1*, *Qn*, *P2*, …, *Q2*, *Pm*, *Q1*.
///
/// ## Monitoring Progress
///
/// To monitor an operation’s progress, access its `progress` property. That property’s 
/// `totalUnitCount` is the total number of pages that will be in the output PDF; its
/// `completedUnitCount` is the number of pages that have been written to the output PDF so far.
class CombineScansOperation: ConcurrentProgressReportingOperation {
    /// The types of errors that can occur during the execution of the operation.
    enum Error: ErrorType {
        /// Indicates that the input PDF located at the associated `NSURL` could not be opened.
        case CouldNotOpenFileURL(NSURL)

        /// Indicates that an output PDF could not be created at the associated `NSURL`.
        case CouldNotCreateOutputPDF(NSURL)
    }

    /// The file URL of the PDF whose contents are the front pages of a printed work.
    let frontPagesPDFURL: NSURL

    /// The file URL of the PDF whose contents are the back pages of a printed work in reverse order.
    let reversedBackPagesPDFURL: NSURL

    /// The file URL at which to store the output PDF.
    let outputPDFURL: NSURL

    /// Contains an error that occurred during execution of the instance. If nil, no error occurred.
    /// If this is set, the operation finished unsuccessfully.
    private(set) var error: Error?

    
    /// Initializes a newly created `CombineScansOperation` instance with the specified front pages PDF
    /// URL, reversed back pages PDF URL, and output PDF URL.
    ///
    /// - parameter frontPagesPDFURL: The file URL of the PDF whose contents are the front pages of 
    ///     a printed work.
    /// - parameter reversedBackPagesPDFURL: The file URL of the PDF whose contents are the back pages
    ///     of a printed work in reverse order.
    /// - parameter outputPDFURL: The file URL at which to store the output PDF.
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


/// Instances of `ScannedPagesGenerator` generate a sequence of `CGPDFPage` objects from two PDFs.
/// The order of the pages is that described in the `CombineScansOperation` class documentation.
private struct ScannedPagesGenerator: GeneratorType {
    /// Indicates whether the next page should come from the front pages PDF.
    var nextPageIsFront: Bool

    /// The generator for pages from the front pages PDF document.
    var frontPageGenerator: PDFDocumentPageGenerator

    /// The generator for pages from the back pages PDF document. This generator returns pages
    /// in reverse order.
    var backPageGenerator: PDFDocumentPageGenerator

    /// Initializes a newly created `ScannedPagesGenerator` instance with the specified front pages PDF
    /// document and reversed back pages PDF document.
    init(frontPagesDocument: CGPDFDocument, reversedBackPagesDocument: CGPDFDocument) {
        nextPageIsFront = true
        let frontPageNumbers = Array(1 ..< (CGPDFDocumentGetNumberOfPages(frontPagesDocument) + 1))
        let backPageNumbers = Array((1 ..< (CGPDFDocumentGetNumberOfPages(reversedBackPagesDocument) + 1)).reverse())

        frontPageGenerator = PDFDocumentPageGenerator(document: frontPagesDocument, pageNumbers: frontPageNumbers)
        backPageGenerator = PDFDocumentPageGenerator(document: reversedBackPagesDocument, pageNumbers: backPageNumbers)
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

/// Instances of `PDFDocumentPageGenerator` generate a sequence of `CGPDFPage` objects from a single PDF
/// document using an array of page numbers specified at initialization time. For example, a generator
/// initialized like
///
/// ```
/// var generator = PDFDocumentPageGenerator(document, [1, 3, 2, 4, 4])
/// ```
///
/// would return the 1st, 3rd, 2nd, 4th, and 4th pages of the specified PDF document.
private struct PDFDocumentPageGenerator: GeneratorType {
    /// The PDF document from which the instance gets pages.
    let document: CGPDFDocument

    /// An indexing generator that returns the next page number to get from the PDF document.
    var pageNumberGenerator: IndexingGenerator<[Int]>

    /// Initializes a newly created `PDFDocumentPageGenerator` with the specified document and page numbers.
    /// - parameter document: The PDF document from which the instance gets pages.
    /// - parameter pageNumbers: The sequence of page numbers that the generator should use when getting pages.
    init(document: CGPDFDocument, pageNumbers: [Int]) {
        self.document = document
        pageNumberGenerator = pageNumbers.generate()
    }

    mutating func next() -> CGPDFPage? {
        guard let pageNumber = pageNumberGenerator.next() else {
            return nil
        }

        return CGPDFDocumentGetPage(document, pageNumber)
    }
}
