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
        var rangeFrom = startIndex
        var rangeTo = endIndex

        if let from = from, let index = range(of: from)?.upperBound {
            rangeFrom = index
        }

        if let to = to, let index = range(of: to)?.lowerBound {
            rangeTo = index
        }

        return String(self[rangeFrom..<rangeTo])
    }
}
