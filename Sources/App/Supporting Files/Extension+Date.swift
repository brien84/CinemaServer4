//
//  Extension+Date.swift
//  
//
//  Created by Marius on 2023-10-24.
//

import Foundation

extension Date {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-d HH:mm"
        return formatter
    }()

    /// Returns `String` representation of the `Date`, formatted as "2023-10-15 13:15".
    var formatted: String {
        Self.formatter.string(from: self)
    }
}
