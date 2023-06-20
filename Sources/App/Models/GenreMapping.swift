//
//  GenreMapping.swift
//  
//
//  Created by Marius on 2023-06-19.
//

import Fluent
import Vapor

final class GenreMapping: Model, Content {
    static let schema = "genre_mappings"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "genre")
    var genre: String

    @Field(key: "new_genre")
    var newGenre: String
}

struct CreateGenreMappings: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("genre_mappings")
            .id()
            .field("genre", .string, .required)
            .field("new_genre", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("genre_mappings").delete()
    }
}
