//
//  StringExtension.swift
//  HorizonCalendar3
//
//  Created by Kyle Rosenbluth on 9/6/14.
//  Copyright (c) 2014 Kyle Rosenbluth. All rights reserved.
//

import Foundation

extension String {
    subscript (i: Int) -> String {
        return String(Array(self)[i])
    }

    func firstOne() -> String {
        return count(self) > 0 ? self[0] : ""
    }
    
    func secondOne() -> String {
        return count(self) > 2 ? self[1] : ""
    }

    func firstThree() -> String {
        return count(self) > 2 ? self[0] + self[1] + self[2] : ""
    }
    
    subscript (r: Range<Int>) -> String {
        let start = advance(self.startIndex, r.startIndex)
        var end = advance(startIndex, r.endIndex)
        return substringWithRange(Range(start: start, end: end))
    }
    
    subscript (r: NSRange) -> String {
        return self[r.location..<r.location + r.length]
    }
}