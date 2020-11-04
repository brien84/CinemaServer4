//
//  MovieValidator.swift
//  
//
//  Created by Marius on 2020-10-25.
//

import Fluent
import Vapor

enum ValidationError: Error {
    case failed
}

protocol MovieValidation {
    func validate(on db: Database) -> EventLoopFuture<Void>
}

final class MovieValidator: MovieValidation {
    func validate(on db: Database) -> EventLoopFuture<Void> {
        Movie.query(on: db).with(\.$showings).all().flatMap { movies in
            movies.map {
                self.validate(movie: $0, on: db)
            }.flatten(on: db.eventLoop)
        }
    }

    private func validate(movie: Movie, on db: Database) -> EventLoopFuture<Void> {
        do {
            let title = movie.title
            try validate(property: title)

            let originalTitle = movie.originalTitle
            try validate(property: originalTitle)

            let year = movie.year
            try validate(property: year)

            let duration = movie.duration
            try validate(property: duration)

            let ageRating = movie.ageRating
            try validate(property: ageRating)

            let genres = movie.genres
            try validate(property: genres)

            let plot = movie.plot
            try validate(property: plot)

            let poster = movie.poster
            try validate(property: poster)

            let showings = movie.showings
            try validate(property: showings)

            return db.eventLoop.makeSucceededFuture(())
        } catch {
            return movie.delete(on: db)
        }
    }

    private func validate<T>(property: T?) throws {
        if property == nil {
            throw ValidationError.failed
        }

        if let string = property as? String, string.isEmpty {
            throw ValidationError.failed
        }

        if let stringArray = property as? [String], stringArray.isEmpty {
            throw ValidationError.failed
        }

        if let showingArray = property as? [Showing], showingArray.isEmpty {
            throw ValidationError.failed
        }
    }
}
