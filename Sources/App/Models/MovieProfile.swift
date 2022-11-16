//
//  MovieProfile.swift
//  
//
//  Created by Marius on 2020-10-21.
//

import Fluent
import Vapor

/// Persistent record of `Movie` properties, which can be applied to a newly fetched `Movie` to keep data consistency.
/// `MovieProfile` can be edited manually in a database in order to fix data errors provided by the API.
final class MovieProfile: Model, Content {
    static let schema = "movie_profiles"

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

    convenience init(
        title: String?, originalTitle: String?, year: String?,
        duration: String?, ageRating: String?, genres: [String]?,
        plot: String?
    ) {
        self.init()
        self.title = title
        self.originalTitle = originalTitle
        self.year = year
        self.duration = duration
        self.ageRating = ageRating
        self.genres = genres
        self.plot = plot
    }

    convenience init(from movie: Movie) {
        self.init()
        self.title = movie.title
        self.originalTitle = movie.originalTitle
        self.year = movie.year
        self.duration = movie.duration
        self.ageRating = movie.ageRating
        self.genres = movie.genres
        self.plot = movie.plot
    }
}

struct CreateMovieProfiles: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("movie_profiles")
            .id()
            .field("title", .string)
            .field("original_title", .string)
            .field("year", .string)
            .field("duration", .string)
            .field("age_rating", .string)
            .field("genres", .array(of: .string))
            .field("plot", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("movie_profiles").delete()
    }
}
