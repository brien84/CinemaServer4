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
    var ageRating: AgeRating?

    @Field(key: "genres")
    var genres: [String]?

    @Field(key: "metadata")
    var metadata: [String]?

    @Field(key: "plot")
    var plot: String?
}

struct CreateMovieProfiles: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(MovieProfile.schema)
            .id()
            .field("title", .string)
            .field("original_title", .string)
            .field("year", .string)
            .field("duration", .string)
            .field("age_rating", .string)
            .field("genres", .array(of: .string))
            .field("metadata", .array(of: .string))
            .field("plot", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(MovieProfile.schema).delete()
    }
}
