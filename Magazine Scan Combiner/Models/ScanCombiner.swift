//
//  ScanCombiner.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/3/2016.
//  Copyright © 2016 Quantum Lens Cap. All rights reserved.
//

import Cocoa


class ScanCombiner {
    enum Error: ErrorType {
        case CouldNotOpenInputPDF(NSURL)
        case CouldNotCreateOutputPDF
    }

    
    lazy var operationQueue: NSOperationQueue = {
        let operationQueue = NSOperationQueue()
        operationQueue.name = String(format: "ScanCombiner.\(unsafeAddressOf(self))")
        return operationQueue
    }()


    func combineScansWithFrontPagesPDFURL(frontURL: NSURL, reversedBackPagesPDFURL backURL: NSURL, outputURL: NSURL) throws -> NSProgress {
        let frontPagesDocument = try PDFDocumentWithURL(frontURL)
        let reversedBackPagesDocument = try PDFDocumentWithURL(backURL)
        guard let outputContext = CGPDFContextCreateWithURL(outputURL, nil, nil) else {
            throw Error.CouldNotCreateOutputPDF
        }

        let pageCount = CGPDFDocumentGetNumberOfPages(frontPagesDocument) + CGPDFDocumentGetNumberOfPages(reversedBackPagesDocument)
        let progress = NSProgress(totalUnitCount: Int64(pageCount))

        var pageGenerator = ScannedPagesGenerator(frontPagesDocument: frontPagesDocument, reversedBackPagesDocument: reversedBackPagesDocument)

        operationQueue.addOperationWithBlock {
            while let page = pageGenerator.next() {
                // Start a new page in our output, get the contents of the page from our input, write that page to our output
                var mediaBox = CGPDFPageGetBoxRect(page, .MediaBox)
                CGContextBeginPage(outputContext, &mediaBox)
                CGContextDrawPDFPage(outputContext, page)
                CGContextEndPage(outputContext)
                progress.completedUnitCount += 1
            }

            CGPDFContextClose(outputContext)
        }

        return progress
    }

    private func PDFDocumentWithURL(inputURL: NSURL) throws -> CGPDFDocument {
        guard let document = CGPDFDocumentCreateWithURL(inputURL) else {
            throw Error.CouldNotOpenInputPDF(inputURL)
        }
        
        return document
    }
}


struct ScannedPagesGenerator: GeneratorType {
    private var nextPageIsFront: Bool
    private var frontPageGenerator: PDFDocumentPageGenerator
    private var backPageGenerator: PDFDocumentPageGenerator

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


struct PDFDocumentPageGenerator: GeneratorType {
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
