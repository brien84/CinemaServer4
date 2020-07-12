//
//  Extensions.swift
//  
//
//  Created by Marius on 2020-07-08.
//

import Foundation

extension String {
    func convertToDate() -> Date? {
        let dateFormatter = DateFormatter()

        guard let timeZone = TimeZone(identifier: "Europe/Vilnius") else { fatalError("TimeZone not found!") }
        dateFormatter.timeZone = timeZone

        // ForumCinemas, Multikino format: 2019-09-26T17:30:00
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
        if let date = dateFormatter.date(from: self) {
            return date
        }

        // Cinamon format: 2019-09-26 17:30:00
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss"
        if let date = dateFormatter.date(from: self) {
            return date
        }

        return nil
    }

    // Returns part of the `String` between the provided `String` parameters.
    //
    // If parameters are nil, the string is sliced from the beginning to the end.
    func slice(from: String?, to: String?) -> String? {
        guard let rangeFrom = from == nil ? startIndex : range(of: from!)?.upperBound else { return nil }
        guard let rangeTo = to == nil ? endIndex : range(of: to!)?.lowerBound else { return nil }

        return String(self[rangeFrom..<rangeTo])
    }
}