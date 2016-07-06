//
//  String+TildeExpansion.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/5/2016.
//  Copyright © 2016 Quantum Lens Cap. All rights reserved.
//

import Foundation


extension String {
    var stringByExpandingTildeInPath: String {
        return (self as NSString).stringByExpandingTildeInPath
    }


    var stringByAbbreviatingWithTildeInPath: String {
        return (self as NSString).stringByAbbreviatingWithTildeInPath
    }
}
