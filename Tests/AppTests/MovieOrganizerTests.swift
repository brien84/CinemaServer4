//
//  MovieOrganizerTests.swift
//
//
//  Created by Marius on 2020-10-25.
//

@testable import App
import XCTVapor

final class MovieOrganizerTests: XCTestCase {
    var app: Application!
    var sut: MovieOrganizer!

    override func setUp() {
        app = try! Application.testable()
        sut = MovieOrganizer()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testMappingOriginalTitles() throws {
        let currentTitle = "TestTitle"
        let newTitle = "NewTestTitle"
        Movie.create(originalTitle: currentTitle, on: app.db)
        TitleMapping.create(originalTitle: currentTitle, newOriginalTitle: newTitle, on: app.db)

        _ = try sut.organize(on: app.db).wait()

        let movies = try Movie.query(on: app.db).all().wait()

        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].originalTitle, newTitle)
    }

    func testMovieProfileGetsCreated() throws {
        let title = "TestTitle"
        let originalTitle = "TestTitle"
        let year = "TestYear"
        let duration = "TestDuration"
        let ageRating = "TestAgeRating"
        let genres = ["TestGenre"]
        let plot = "TestPlot"

        Movie.create(title: title, originalTitle: originalTitle, year: year, duration: duration,
                     ageRating: ageRating, genres: genres, plot: plot, poster: "", on: app.db)

        _ = try sut.organize(on: app.db).wait()

        let profile = try MovieProfile.query(on: app.db).first().wait()

        XCTAssertEqual(profile?.title, title)
        XCTAssertEqual(profile?.originalTitle, originalTitle)
        XCTAssertEqual(profile?.year, year)
        XCTAssertEqual(profile?.duration, duration)
        XCTAssertEqual(profile?.ageRating, ageRating)
        XCTAssertEqual(profile?.genres, genres)
        XCTAssertEqual(profile?.plot, plot)
    }

    func testNewProfileIsNotCreatedIfOneAlreadyExists() throws {
        let originalTitle = "TestTitle"
        MovieProfile.create(title: "", originalTitle: originalTitle, year: "",
                            duration: "", ageRating: "", genres: [], plot: "", on: app.db)
        Movie.create(title: "", originalTitle: originalTitle, year: "",
                     duration: "", ageRating: "", genres: [], plot: "", poster: "", on: app.db)

        _ = try sut.organize(on: app.db).wait()

        let count = try MovieProfile.query(on: app.db).count().wait()
        XCTAssertEqual(count, 1)
    }

    func testApplyingProfiles() throws {
        let title = "TestTitle"
        let originalTitle = "TestTitle"
        let year = "TestYear"
        let duration = "TestDuration"
        let ageRating = "TestAgeRating"
        let genres = ["TestGenre"]
        let plot = "TestPlot"

        Movie.create(title: "", originalTitle: originalTitle, year: "",
                     duration: "", ageRating: "", genres: [""], plot: "", on: app.db)
        MovieProfile.create(title: title, originalTitle: originalTitle, year: year,
                            duration: duration, ageRating: ageRating, genres: genres, plot: plot, on: app.db)

        _ = try sut.organize(on: app.db).wait()

        let movies = try Movie.query(on: app.db).all().wait()

        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].title, title)
        XCTAssertEqual(movies[0].originalTitle, originalTitle)
        XCTAssertEqual(movies[0].year, year)
        XCTAssertEqual(movies[0].duration, duration)
        XCTAssertEqual(movies[0].ageRating, ageRating)
        XCTAssertEqual(movies[0].genres, genres)
        XCTAssertEqual(movies[0].plot, plot)
    }
}
