//
//  Venue.swift
//  
//
//  Created by Marius on 2022-12-07.
//

import Foundation

enum Venue: String, Codable {
    case apollo
    case apolloAkropolis
    case apolloOutlet
    case atlantis
    case cinamon
    case forum
    case multikino

    // MARK: - Deprecated

    case apollo_ = "Apollo"
    case cinamon_ = "Cinamon"
    case forum_ = "Forum Cinemas"
    case multikino_ = "Multikino"
}
