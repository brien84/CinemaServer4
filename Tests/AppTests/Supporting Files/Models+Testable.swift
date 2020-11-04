//
//  Models+Testable.swift
//
//
//  Created by Marius on 2020-10-26.
//

@testable import App
import Fluent

extension Movie {
    static func create(title: String? = nil, originalTitle: String? = nil, year: String? = nil,
                       duration: String? = nil, ageRating: String? = nil, genres: [String]? = nil,
                       plot: String? = nil, poster: String? = nil, showings: [Showing]? = nil, on db: Database) {

        let movie = Movie(title: title, originalTitle: originalTitle, year: year, duration: duration,
                          ageRating: ageRating, genres: genres, plot: plot, poster: poster)

        try! movie.create(on: db).wait()

        if let showings = showings {
            try! movie.$showings.create(showings, on: db).wait()
        } else {
            // Adds one `Showing`, so movies do not get deleted, while
            // executing `cleanup()` method during `MovieOrganizer` tests.
            let showings = [Showing(city: "", date: Date(), venue: "", is3D: true, url: "")]
            try! movie.$showings.create(showings, on: db).wait()
        }
    }
}
