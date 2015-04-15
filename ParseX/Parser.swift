//
//  Parser.swift
//  ParseX
//
//  Created by Kyle & Jeffrey Rosenbluth on 9/8/14.
//  Copyright (c) 2014-15 Kyle &Jeffrey Rosenbluth. All rights reserved.
//

import Foundation

public typealias LexResult = (strippedInput: String, groups: [String])

public struct Interpreter<D> {
    let eval: LexResult -> D
}

public func extract(re: String, query: String) -> LexResult? {
    let regex = NSRegularExpression(pattern: re, options: .CaseInsensitive, error: nil)
    assert(regex != nil, "Invalid Regular Expression")
    if let match = regex!.firstMatchInString(query, options: nil, range: NSMakeRange(0, count(query))) {
        let newString = regex!.stringByReplacingMatchesInString(query, options: nil, range: match.range, withTemplate: "")
        var groups: [String] = []
        for var i = 1; i < match.numberOfRanges;  ++i {
            let range = match.rangeAtIndex(i)
            // Check for empty ranges since Apple includes them in numberOfRanges.
            if range.length > 0 { groups.append(query[range]) }
        }
        return (newString, groups)
    }
    return (nil)
}

public struct Parser<R> {
    let parse : String -> (result: R, strippedInput: String)?
}

public func buildParser<T>(re: String, interpret: Interpreter<T>) -> Parser<T> {
    let parser: Parser<T> = Parser { q in
        if let lexResult = extract(re, q) { return (interpret.eval(lexResult), lexResult.strippedInput) }
        return nil
    }
    return parser
}


// Functor - fmap.
infix operator <^> {associativity left precedence 140}
public func <^> <R,S>(f: R -> S, r: Parser<R>) -> Parser<S> {
    let result: Parser<S> = Parser {q in
        if let (rResult, rString) = r.parse(q) { return (f(rResult), rString) }
        return nil
    }
    return result
}

// Run the parser on the right and if it succeeds return the value on the left.
infix operator <^ {associativity left precedence 140}
public func <^ <R,S>(r: R, s: Parser<S>) -> Parser<R> {
    let result: Parser<R> = Parser {q in
        if let (sResult, sString) = s.parse(q) { return (r, sString) }
        return nil
    }
    return result
}

// Run the parser on the left and if it succeeds return the value on the right b.
infix operator ^> {associativity left precedence 140}
public func ^> <R,S>(r: Parser<R>, s: S) -> Parser<S> {
    let result: Parser<S> = Parser {q in
        if let (rResult, rString) = r.parse(q) { return (s, rString) }
        return nil
    }
    return result
}

// Applicative functor - pure, and apply.
public func pure<R>(value: R) -> Parser<R> {
    return Parser {q in (value, q)}
}

// Usage: f <^> p1 <*> p2, where f is a combining function
// in curried form, e.g. func f(a: Character)(b: Character) -> (a,b)
infix operator <*> {associativity left precedence 140}
public func <*> <R,S>(f: Parser<R -> S>, r: Parser<R>) -> Parser<S> {
    let result: Parser<S> = Parser {q in
        if let (fResult, fString) = f.parse(q) {
            if let (rResult, rString) = r.parse(fString) { return (fResult(rResult), rString) }
            return nil
        }
        return nil
    }
    return result
}

// Usage: p1 *> p2, apply p1 followed by p2 and take the result of p2 throwing
// away the result of p1. If either parser fails then the combined parser fails.
infix operator *> {associativity left precedence 140}
public func *> <R,S>(r: Parser<R>, s: Parser<S>) -> Parser<S> {
    let result: Parser<S> = Parser {q in
        if let (rResult, rString) = r.parse(q) {
            if let (sResult, sString) = s.parse(rString) { return (sResult, sString) }
            return nil
        }
        return nil
    }
    return result
}

// Like *> but keeps the result of p1 and throws away the result of p2.
infix operator <* {associativity left precedence 140}
public func <* <R,S>(r: Parser<R>, s: Parser<S>) -> Parser<R> {
    let result: Parser<R> = Parser {q in
        if let (rResult, rString) = r.parse(q) {
            if let (sResult, sString) = s.parse(rString) { return (rResult, rString) }
            return nil
        }
        return nil
    }
    return result
}

// Alternative
infix operator <|> {associativity left precedence 130}
public func <|> <R>(r1: Parser<R>, r2: Parser<R>) -> Parser<R> {
    let result: Parser<R> = Parser {q in
        if let r = r1.parse(q) { return r }
        return r2.parse(q)
    }
    return result
}