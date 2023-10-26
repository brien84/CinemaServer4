//
//  AgeRating.swift
//  
//
//  Created by Marius on 2023-10-26.
//

import Foundation

enum AgeRating: String, Codable {
    case v = "V"
    case n7 = "N-7"
    case n13 = "N-13"
    case n16 = "N-16"
    case n18 = "N-18"

    init?(rawValue: String) {
        switch rawValue {
        case "V":
            self = .v
        case "N-7", "N7", "7":
            self = .n7
        case "N-13", "N13", "13":
            self = .n13
        case "N-16", "N16", "16":
            self = .n16
        case "N-18", "N18", "18":
            self = .n18
        default:
            return nil
        }
    }

    init?(rawValue: String?) {
        guard let rawValue else { return nil }
        self.init(rawValue: rawValue)
    }
}
