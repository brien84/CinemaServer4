//
//  Showing.swift
//  
//
//  Created by Marius on 2020-07-07.
//

import Vapor

final class Showing: Content {
    let id: UUID?
    let city: String
    let date: Date
    let venue: String
    let is3D: Bool
    let url: String

    init(id: UUID? = nil, city: String, date: Date, venue: String, is3D: Bool, url: String) {
        self.id = id
        self.city = city
        self.date = date
        self.venue = venue
        self.is3D = is3D
        self.url = url
    }
}
