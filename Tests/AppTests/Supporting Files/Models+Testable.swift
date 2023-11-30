//
//  Models+Testable.swift
//
//
//  Created by Marius on 2020-10-26.
//

@testable import App
import Fluent
import Foundation

extension Featured {
    convenience init(
        id: UUID? = UUID(),
        label: String = "",
        title: String = "",
        originalTitle: String,
        startDate: Date,
        endDate: Date,
        imageURL: String? = nil
    ) {
        self.init()
        self.id = id
        self.label = label
        self.title = title
        self.originalTitle = originalTitle
        self.startDate = startDate
        self.endDate = endDate
        self.imageURL = imageURL
    }

    static func create(
        id: UUID? = UUID(),
        label: String = "",
        title: String = "",
        originalTitle: String = "",
        startDate: Date = Date(),
        endDate: Date = Date(),
        imageURL: String? = nil,
        on db: Database
    ) -> Featured {
        let featured = Featured(
            id: id,
            label: label,
            title: title,
            originalTitle: originalTitle,
            startDate: startDate,
            endDate: endDate,
            imageURL: imageURL
        )

        try! featured.create(on: db).wait()
        return featured
    }
}

extension Movie {
    static func create(
        title: String? = nil,
        originalTitle: String? = nil,
        year: String? = nil,
        duration: String? = nil,
        ageRating: AgeRating? = nil,
        genres: [String]? = nil,
        metadata: [String]? = nil,
        plot: String? = nil,
        poster: String? = nil,
        showings: [Showing]? = nil,
        on db: Database
    ) {
        let movie = Movie(
            title: title,
            originalTitle: originalTitle,
            year: year,
            duration: duration,
            ageRating: ageRating,
            genres: genres,
            metadata: metadata,
            plot: plot,
            poster: poster
        )

        try! movie.create(on: db).wait()

        if let showings = showings {
            try! movie.$showings.create(showings, on: db).wait()
        } else {
            // Adds a placeholder `Showing` to prevent the `Movie` object from being deleted
            // when the `cleanup()` method is invoked during `MovieOrganizer` tests.
            let showings = [Showing(city: .vilnius, date: Date(), venue: .forum, is3D: true, url: "")]
            try! movie.$showings.create(showings, on: db).wait()
        }
    }
}

extension MovieProfile {
    convenience init(
        title: String?,
        originalTitle: String?,
        year: String?,
        duration: String?,
        ageRating: AgeRating?,
        genres: [String]?,
        metadata: [String]?,
        plot: String?
    ) {
        self.init()
        self.title = title
        self.originalTitle = originalTitle
        self.year = year
        self.duration = duration
        self.ageRating = ageRating
        self.genres = genres
        self.metadata = metadata
        self.plot = plot
    }

    static func create(
        title: String? = nil,
        originalTitle: String? = nil,
        year: String? = nil,
        duration: String? = nil,
        ageRating: AgeRating? = nil,
        genres: [String]? = nil,
        metadata: [String]? = nil,
        plot: String? = nil,
        on db: Database
    ) {
        let profile = MovieProfile(
            title: title,
            originalTitle: originalTitle,
            year: year,
            duration: duration,
            ageRating: ageRating,
            genres: genres,
            metadata: metadata,
            plot: plot
        )

        try! profile.create(on: db).wait()
    }
}

extension Showing {
    convenience init(
        city: City = .vilnius,
        date: Date = Date(),
        venue: Venue = .forum,
        is3D: Bool = false,
        url: String = ""
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
