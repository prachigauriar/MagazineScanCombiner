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

/// The `ErrorBox` type is used to box an error inside a struct. It’s necessary to use `ErrorBox`
/// to store `Error` properties on `NSObject` subclasses in Xcode 8b4 and 8b5 due to a bug.
struct ErrorBox<ErrorType: Error> {
    let error: ErrorType

    init(_ error: ErrorType) {
        self.error = error
    }
}


/// The types of errors that can occur during the execution of the operation.
enum CombineScansError : Error {
    /// Indicates that the input PDF located at the associated `URL` could not be opened.
    case couldNotOpenFileURL(URL)

    /// Indicates that an output PDF could not be created at the associated `URL`.
    case couldNotCreateOutputPDF(URL)
}


/// `CombineScansOperation` is an `Operation` subclass that combines the pages of two PDFs into a
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
class CombineScansOperation : ConcurrentProgressReportingOperation {
    /// The file URL of the PDF whose contents are the front pages of a printed work.
    let frontPagesPDFURL: URL

    /// The file URL of the PDF whose contents are the back pages of a printed work in reverse order.
    let reversedBackPagesPDFURL: URL

    /// The file URL at which to store the output PDF.
    let outputPDFURL: URL

    /// Contains an error that occurred during execution of the instance. If nil, no error occurred.
    /// If this is set, the operation finished unsuccessfully.
    private(set) var errorBox: ErrorBox<CombineScansError>?

    /// Initializes a newly created `CombineScansOperation` instance with the specified front pages PDF
    /// URL, reversed back pages PDF URL, and output PDF URL.
    ///
    /// - parameter frontPagesPDFURL: The file URL of the PDF whose contents are the front pages of 
    ///     a printed work.
    /// - parameter reversedBackPagesPDFURL: The file URL of the PDF whose contents are the back pages
    ///     of a printed work in reverse order.
    /// - parameter outputPDFURL: The file URL at which to store the output PDF.
    init(frontPagesPDFURL: URL, reversedBackPagesPDFURL: URL, outputPDFURL: URL) {
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
        guard !isFinished && !isCancelled else {
            return 
        }

        isExecuting = true

        // However we exit, we want to mark ourselves as no longer executing
        defer { isFinished = true }

        // If we couldn’t open the front pages PDF, set our error, finish, and exit
        guard let frontPagesDocument = CGPDFDocument(frontPagesPDFURL) else {
            errorBox = ErrorBox(.couldNotOpenFileURL(frontPagesPDFURL))
            return
        }

        // If we couldn’t open the reversed back pages PDF, set our error, finish, and exit
        guard let reversedBackPagesDocument = CGPDFDocument(reversedBackPagesPDFURL) else {
            errorBox = ErrorBox(.couldNotOpenFileURL(reversedBackPagesPDFURL))
            return
        }

        // If we couldn’t create the output PDF context, set our error, finish, and exit
        guard let outputPDFContext = CGContext(outputPDFURL, mediaBox: nil, nil) else {
            errorBox = ErrorBox(.couldNotCreateOutputPDF(outputPDFURL))
            return
        }

        let pageCount = frontPagesDocument.numberOfPages + reversedBackPagesDocument.numberOfPages
        progress.totalUnitCount = Int64(pageCount)

        for page in ScannedPageSequence(frontPagesDocument: frontPagesDocument, reversedBackPagesDocument: reversedBackPagesDocument) {
            guard !isCancelled else {
                break
            }

            // Start a new page in our output, get the contents of the page from our input, write that page to our output
            var mediaBox = page.getBoxRect(.mediaBox)
            outputPDFContext.beginPage(mediaBox: &mediaBox)
            outputPDFContext.drawPDFPage(page)
            outputPDFContext.endPage()
            progress.completedUnitCount += 1
        }

        outputPDFContext.closePDF()

        // If we were canceled, try to remove the output PDF, but don’t worry about it if we can’t
        if isCancelled {
            do {
                try FileManager.default.removeItem(at: outputPDFURL)
            } catch {
            }
        }
    }
}


/// Instances of `ScannedPagesSequence` generate a sequence of `CGPDFPage` objects from two PDFs.
/// The order of the pages is that described in the `CombineScansOperation` class documentation.
private struct ScannedPageSequence : Sequence, IteratorProtocol {
    /// Indicates whether the next page should come from the front pages PDF.
    var isNextPageFromFront: Bool

    /// The iterator for pages from the front pages PDF document.
    var frontPageIterator: PDFDocumentPageIterator

    /// The iterator for pages from the back pages PDF document. This iterator returns pages
    /// in reverse order.
    var backPageIterator: PDFDocumentPageIterator

    /// Initializes a newly created `ScannedPagesSequence` instance with the specified front pages PDF
    /// document and reversed back pages PDF document.
    init(frontPagesDocument : CGPDFDocument, reversedBackPagesDocument: CGPDFDocument) {
        isNextPageFromFront = true
        let frontPageNumbers = 1 ..< (frontPagesDocument.numberOfPages + 1)
        let backPageNumbers = (1 ..< (reversedBackPagesDocument.numberOfPages + 1)).reversed()

        frontPageIterator = PDFDocumentPageIterator(document: frontPagesDocument, pageNumbers: frontPageNumbers)
        backPageIterator = PDFDocumentPageIterator(document: reversedBackPagesDocument, pageNumbers: backPageNumbers)
    }


    mutating func next() -> CGPDFPage? {
        let page: CGPDFPage?

        defer { isNextPageFromFront = !isNextPageFromFront }

        if isNextPageFromFront {
            return frontPageIterator.next() ?? backPageIterator.next()
        } else {
            return backPageIterator.next() ?? frontPageIterator.next()
        }
    }
}


/// Instances of `PDFDocumentPageIterator` iterate over a sequence of `CGPDFPage` objects from a single PDF
/// document using a sequence of page numbers specified at initialization time. For example, an iterator
/// initialized like
///
/// ```
/// var iterator = PDFDocumentPageIterator(document, [1, 3, 2, 4, 4])
/// ```
///
/// would return the 1st, 3rd, 2nd, 4th, and 4th pages of the specified PDF document.
private struct PDFDocumentPageIterator : IteratorProtocol {
    /// The PDF document from which the instance gets pages.
    let document: CGPDFDocument

    /// An Int iterator that returns the next page number to get from the PDF document.
    var pageNumberIterator: AnyIterator<Int>

    /// Initializes a newly created `PDFDocumentPageIterator` with the specified document and page numbers.
    /// - parameter document: The PDF document from which the instance gets pages.
    /// - parameter pageNumbers: The sequence of page numbers that the iterator should use when getting pages.
    init<IntSequence: Sequence>(document: CGPDFDocument, pageNumbers: IntSequence) where IntSequence.Iterator.Element == Int {
        self.document = document
        pageNumberIterator = AnyIterator(pageNumbers.makeIterator())
    }


    mutating func next() -> CGPDFPage? {
        guard let pageNumber = pageNumberIterator.next() else {
            return nil
        }

        return document.page(at: pageNumber)
    }
}
