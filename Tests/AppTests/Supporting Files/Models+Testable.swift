//
//  Models+Testable.swift
//
//
//  Created by Marius on 2020-10-26.
//

@testable import App
import Fluent
import Foundation

extension Movie {
    static func create(
        title: String? = nil, originalTitle: String? = nil, year: String? = nil,
        duration: String? = nil, ageRating: String? = nil, genres: [String]? = nil,
        plot: String? = nil, poster: String? = nil, showings: [Showing]? = nil, on db: Database
    ) {
        let movie = Movie(
            title: title,
            originalTitle: originalTitle,
            year: year,
            duration: duration,
            ageRating: ageRating,
            genres: genres,
            plot: plot,
            poster: poster
        )

        try! movie.create(on: db).wait()

        if let showings = showings {
            try! movie.$showings.create(showings, on: db).wait()
        } else {
            // Adds one `Showing`, so movies do not get deleted, while
            // executing `cleanup()` method during `MovieOrganizer` tests.
            let showings = [Showing(city: .vilnius, date: Date(), venue: .forum, is3D: true, url: "")]
            
            try! movie.$showings.create(showings, on: db).wait()
        }
    }
}

extension MovieProfile {
    static func create(
        title: String? = nil, originalTitle: String? = nil, year: String? = nil,
        duration: String? = nil, ageRating: String? = nil, genres: [String]? = nil,
        plot: String? = nil, on db: Database
    ) {
        let profile = MovieProfile(
            title: title,
            originalTitle: originalTitle,
            year: year,
            duration: duration,
            ageRating: ageRating,
            genres: genres,
            plot: plot
        )

        try! profile.create(on: db).wait()
    }
}

extension Showing {
    convenience init(
        city: City = .vilnius, date: Date = Date(),
        venue: Venue = .forum, is3D: Bool = false, url: String = ""
    ) {
        self.init()
        self.city = city
        self.date = date
        self.venue = venue
        self.is3D = is3D
        self.url = url
    }
}

extension TitleMapping {
    static func create(originalTitle: String, newOriginalTitle: String, on db: Database) {
        let mapping = TitleMapping()
        mapping.originalTitle = originalTitle
        mapping.newOriginalTitle = newOriginalTitle

        try! mapping.create(on: db).wait()
    }
}

extension GenreMapping {
    static func create(genre: String, newGenre: String, on db: Database) {
        let mapping = GenreMapping()
        mapping.genre = genre
        mapping.newGenre = newGenre

        try! mapping.create(on: db).wait()
    }
}
