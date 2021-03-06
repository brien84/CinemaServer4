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

    @Field(key: "original_title")
    var originalTitle: String?

    @Field(key: "year")
    var year: String?

    @Field(key: "duration")
    var duration: String?

    @Field(key: "age_rating")
    var ageRating: String?

    @Field(key: "genres")
    var genres: [String]?

    @Field(key: "plot")
    var plot: String?

    @Field(key: "poster")
    var poster: String?

    @Children(for: \.$movie)
    var showings: [Showing]

    convenience init(title: String?, originalTitle: String?, year: String?, duration: String?,
                     ageRating: String?, genres: [String]?, plot: String? = nil, poster: String? = nil) {
        self.init()

        self.title = title
        self.originalTitle = originalTitle
        self.year = year
        self.duration = duration
        self.ageRating = ageRating
        self.genres = genres
        self.plot = plot
        self.poster = poster
    }
}

extension Movie: Equatable {
    static func == (lhs: Movie, rhs: Movie) -> Bool {
        return lhs.originalTitle?.lowercased() == rhs.originalTitle?.lowercased()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
}

struct CreateMovies: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("movies")
            .id()
            .field("title", .string)
            .field("original_title", .string)
            .field("year", .string)
            .field("duration", .string)
            .field("age_rating", .string)
            .field("genres", .array(of: .string))
            .field("plot", .string)
            .field("poster", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("movies").delete()
    }
}
