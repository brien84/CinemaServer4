//
//  Movie.swift
//  
//
//  Created by Marius on 2020-07-07.
//

import Fluent
import Vapor

final class Movie: Model, Content {
    static let schema = "movies"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String?

    @Field(key: "originalTitle")
    var originalTitle: String?

    @Field(key: "year")
    var year: String?

    @Field(key: "duration")
    var duration: String?

    @Field(key: "ageRating")
    var ageRating: String?

    @Field(key: "genres")
    var genres: [String]?

    @Field(key: "plot")
    var plot: String?

    @Field(key: "poster")
    var poster: String?

    @Field(key: "showings")
    var showings: [Showing]

    init() { }

    init(id: UUID? = nil, title: String?, originalTitle: String?, year: String?, duration: String?,
         ageRating: String?, genres: [String]?, plot: String?, poster: String?, showings: [Showing] = []) {
        self.id = id
        self.title = title
        self.originalTitle = originalTitle
        self.year = year
        self.duration = duration
        self.ageRating = ageRating
        self.genres = genres
        self.plot = plot
        self.poster = poster
        self.showings = showings
    }
}

struct CreateMovies: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("movies")
            .id()
            .field("title", .string, .required)
            .field("originalTitle", .string, .required)
            .field("year", .string, .required)
            .field("duration", .string, .required)
            .field("ageRating", .string, .required)
            .field("genres", .array(of: .string), .required)
            .field("plot", .string, .required)
            .field("poster", .string, .required)
            .field("showings", .array(of: .custom(Showing.self)), .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("movies").delete()
    }
}
