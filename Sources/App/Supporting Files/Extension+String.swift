//
//  Extensions.swift
//  
//
//  Created by Marius on 2020-07-08.
//

import Foundation

extension String {
    /// Capitalizes first `Character` in the `String`.
    var firstCapitalized: String { prefix(1).capitalized + dropFirst() }

    func convertToDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Vilnius")

        // ForumCinemas, Multikino, Apollo format: 2019-09-26T17:30:00
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
        if let date = dateFormatter.date(from: self) {
            return date
        }

        // Cinamon format: 2019-09-26 17:30:00
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss"
        if let date = dateFormatter.date(from: self) {
            return date
        }

        // Atlantis format: 2019-09-26T17:30:00.000Z
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        if let date = dateFormatter.date(from: self) {
            return date
        }

        return nil
    }

    /// Removes " " characters at the beginning and the end of the `String`.
    ///
    /// Example: ` Hello World ` -> `Hello World`
    func trimSpaces() -> String {
        var string = self

        if string.first == " " { string = String(string.dropFirst()) }
        if string.last == " " { string = String(string.dropLast()) }

        return string
    }

    func sanitizeHTTP() -> String {
        return self.replacingOccurrences(of: "http://", with: "https://")
    }

    /// Returns a substring of the `String` between the provided `String` parameters.
    ///
    /// If both `from` and `to` parameters are `nil`, the entire string is returned.
    /// If only `from` parameter is provided, the substring is sliced from the specified `from` index to the end of the string.
    /// If only `to` parameter is provided, the substring is sliced from the beginning of the string to the specified `to` index.
    /// If both `from` and `to` parameters are provided, the substring is sliced from the `from` index to the `to` index.
    /// `isSlicingBackwards` indicates whether slicing should be performed backwards.
    func slice(from: String?, to: String?, isSlicingBackwards: Bool = false) -> String? {
        var rangeFrom = startIndex
        var rangeTo = endIndex
        let options = isSlicingBackwards ? NSString.CompareOptions.backwards : []

        if let from = from, let index = range(of: from, options: options)?.upperBound {
            rangeFrom = index
        }

        if let to = to, let index = range(of: to, options: options)?.lowerBound {
            rangeTo = index
        }

        guard rangeFrom <= rangeTo else { return self }
        return String(self[rangeFrom..<rangeTo])
    }
}
