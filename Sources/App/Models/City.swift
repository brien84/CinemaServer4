//
//  City.swift
//  
//
//  Created by Marius on 2022-11-16.
//

import Foundation

enum City: String, Codable {
    case vilnius
    case kaunas
    case klaipeda
    case siauliai
    case panevezys

    // MARK: - Deprecated

    case vilnius_ = "Vilnius"
    case kaunas_ = "Kaunas"
    case klaipeda_ = "Klaipėda"
    case siauliai_ = "Šiauliai"
    case panevezys_ = "Panevėžys"
}
