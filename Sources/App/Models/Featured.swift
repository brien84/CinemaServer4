//
//  Featured.swift
//  
//
//  Created by Marius on 2023-10-22.
//

import Fluent
import Vapor

final class Featured: Model, Content {
    static let schema = "featured"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "label")
    var label: String

    @Field(key: "title")
    var title: String

    @Field(key: "original_title")
    var originalTitle: String

    @Field(key: "start_date")
    var startDate: Date

    @Field(key: "end_date")
    var endDate: Date

    @Field(key: "image_url")
    var imageURL: String

    @OptionalParent(key: "movie_id")
    var movie: Movie?
}

struct CreateFeatured: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Featured.schema)
            .id()
            .field("label", .string, .required)
            .field("title", .string, .required)
            .field("original_title", .string, .required)
            .field("start_date", .date, .required)
            .field("end_date", .date, .required)
            .field("image_url", .string)
            .field("movie_id", .uuid)
            .unique(on: "movie_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Featured.schema).delete()
    }
}
