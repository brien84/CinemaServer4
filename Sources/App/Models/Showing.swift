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
    var city: City

    @Field(key: "date")
    var date: Date

    @Field(key: "venue")
    var venue: Venue

    @Field(key: "is_3D")
    var is3D: Bool

    @Field(key: "url")
    var url: String

    @Parent(key: "movie_id")
    var movie: Movie

    convenience init(city: City, date: Date, venue: Venue, is3D: Bool, url: String) {
        self.init()
        self.city = city
        self.date = date
        self.venue = venue
        self.is3D = is3D
        self.url = url
    }
}

struct CreateShowings: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Showing.schema)
            .id()
            .field("city", .string)
            .field("date", .datetime)
            .field("venue", .string)
            .field("is_3D", .bool)
            .field("url", .string)
            .field("movie_id", .uuid, .references("movies", "id"))
            .foreignKey("movie_id", references: "movies", "id", onDelete: .cascade)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Showing.schema).delete()
    }
}
