//
//  Showing.swift
//  
//
//  Created by Marius on 2020-07-07.
//

import Fluent
import Vapor

final class Showing: Model, Content {
    static let schema = "showings"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "city")
    var city: String

    @Field(key: "date")
    var date: Date

    @Field(key: "venue")
    var venue: String

    @Field(key: "is3D")
    var is3D: Bool

    @Field(key: "url")
    var url: String

    init() { }

    init(id: UUID? = nil, city: String, date: Date, venue: String, is3D: Bool, url: String) {
        self.id = id
        self.city = city
        self.date = date
        self.venue = venue
        self.is3D = is3D
        self.url = url
    }
}

struct CreateShowings: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("showings")
            .id()
            .field("city", .string, .required)
            .field("date", .date, .required)
            .field("venue", .string, .required)
            .field("is3D", .bool, .required)
            .field("url", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("showings").delete()
    }
}
