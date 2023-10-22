//
//  TitleMapping.swift
//  
//
//  Created by Marius on 2020-10-21.
//

import Fluent
import Vapor

/// Record of `originalTitle` which should be replaced with `newOriginalTitle`,
/// since same `Movie` can have non-identical names in different cinemas.
///
/// `TitleMappings` should be added to the database manually.
final class TitleMapping: Model, Content {
    static let schema = "title_mappings"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "original_title")
    var originalTitle: String

    @Field(key: "new_original_title")
    var newOriginalTitle: String
}

struct CreateTitleMappings: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TitleMapping.schema)
            .id()
            .field("original_title", .string, .required)
            .field("new_original_title", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TitleMapping.schema).delete()
    }
}
