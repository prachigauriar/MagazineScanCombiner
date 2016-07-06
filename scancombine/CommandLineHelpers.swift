//
//  CommandLineHelpers.swift
//  Magazine Scan Combiner
//
//  Created by Prachi Gauriar on 7/5/2016.
//  Copyright © 2016 Quantum Lens Cap. All rights reserved.
//

import Foundation


extension NSProcessInfo {
    var userArgumentCount: Int {
        return self.arguments.count - 1
    }


    var userArguments: [String] {
        guard userArgumentCount > 0 else {
            return []
        }

        return Array(arguments.suffixFrom(1))
    }
}


struct StandardErrorStream: OutputStreamType {
    mutating func write(string: String) {
        fputs(string, stderr)
    }
}

var standardErrorStream = StandardErrorStream()
