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
            let showings = [Showing(city: City.vilnius, date: Date(), venue: "", is3D: true, url: "")]
            
            try! movie.$showings.create(showings, on: db).wait()
        }
    }
}

extension MovieProfile {
    static func create(title: String? = nil, originalTitle: String? = nil, year: String? = nil, duration: String? = nil,
                       ageRating: String? = nil, genres: [String]? = nil, plot: String? = nil, on db: Database) {

        let profile = MovieProfile(title: title, originalTitle: originalTitle, year: year, duration: duration,
                                   ageRating: ageRating, genres: genres, plot: plot)

        try! profile.create(on: db).wait()
    }
}

extension TitleMapping {
    static func create(originalTitle: String, newOriginalTitle: String, on db: Database) {
        let mapping = TitleMapping(originalTitle: originalTitle, newOriginalTitle: newOriginalTitle)

        try! mapping.create(on: db).wait()
    }
}
