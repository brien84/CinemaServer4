//
//  ContentValidator.swift
//
//
//  Created by Marius on 2020-10-25.
//

import Fluent
import Vapor

enum ValidationError: Error {
    case failed
}

protocol ContentValidation {
    func getReport() -> String
    func validate(on db: Database) -> EventLoopFuture<Void>
}

final class ContentValidator: ContentValidation {
    private var invalidFeatured = [Featured]()
    private var invalidMovies = [Movie]()

    func getReport() -> String {
        getMovieReport()
            .appending("<p>-----</p>")
            .appending(getFeaturedReport())
    }

    private func getFeaturedReport() -> String {
        var report: String

        if invalidFeatured.isEmpty {
            report = "<p>All featured passed validation!</p>"
        } else {
            report = "<p>Featured failed validation: </p>"
            invalidFeatured.forEach {
                report.append("<p>\($0.originalTitle)</p>")
            }
        }

        return report
    }

    private func getMovieReport() -> String {
        var report: String

        if invalidMovies.isEmpty {
            report = "<p>All movies passed validation!</p>"
        } else {
            report = "<p>Movies failed validation: </p>"

            let earliestShowings = invalidMovies.compactMap { movie in
                movie.showings.sortedByEarliest().first
            }.sortedByEarliest()

            earliestShowings.forEach { showing in
                if let originalTitle = showing.$movie.value?.originalTitle {
                    let date = showing.date.formatted
                    let url = showing.url
                    report.append(contentsOf: "<p><a href=\"\(url)\">\(originalTitle) | \(date)</a></p>")
                } else {
                    report.append(contentsOf: "<p>Movie is missing originalTitle.</p>")
                }
            }
        }

        return report
    }

    func validate(on db: Database) -> EventLoopFuture<Void> {
        invalidFeatured.removeAll()
        invalidMovies.removeAll()

        let query = Movie.query(on: db)
            .with(\.$featured) { $0.with(\.$movie) }
            .with(\.$showings) { $0.with(\.$movie) }

        return query.all().flatMapEach(on: db.eventLoop) { movie in
            self.validate(movie: movie, on: db).flatMap {
                self.validate(featured: movie.featured, on: db)
            }
        }
    }

    private func validate(featured: Featured?, on db: Database)  -> EventLoopFuture<Void> {
        guard let featured else { return db.eventLoop.makeSucceededFuture(()) }

        do {
            try validate(property: featured.label)
            try validate(property: featured.title)
            try validate(property: featured.originalTitle)
            try validate(property: featured.startDate)
            try validate(property: featured.endDate)
            try validate(property: featured.imageURL)
            return db.eventLoop.makeSucceededFuture(())
        } catch {
            invalidFeatured.append(featured)
            featured.$movie.id = nil
            return featured.update(on: db)
        }
    }

    private func validate(movie: Movie, on db: Database) -> EventLoopFuture<Void> {
        do {
            try validate(property: movie.title)
            try validate(property: movie.originalTitle)
            try validate(property: movie.year)
            try validate(property: movie.duration)
            try validate(property: movie.ageRating)
            try validate(property: movie.genres)
            try validate(property: movie.plot)
            try validate(property: movie.poster)
            try validate(property: movie.showings)
            return db.eventLoop.makeSucceededFuture(())
        } catch {
            invalidMovies.append(movie)
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

private extension Array where Element == Showing {
    func sortedByEarliest() -> [Showing] {
        self.sorted(by: { $0.date < $1.date })
    }
}
