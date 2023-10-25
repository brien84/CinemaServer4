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

    func testMappingGenres() throws {
        let currentGenre = "CurrentGenre"
        let newGenre = "NewGenre"

        Movie.create(originalTitle: "TestMovie", genres: [currentGenre], on: app.db)
        MovieProfile.create(originalTitle: "TestMovie", genres: [currentGenre], on: app.db)
        GenreMapping.create(genre: currentGenre, newGenre: newGenre, on: app.db)

        _ = try sut.organize(on: app.db).wait()
        let movies = try Movie.query(on: app.db).all().wait()

        XCTAssertEqual(movies.first!.genres, [newGenre])
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

    func testCreatingMovieProfile() throws {
        let title = "TestTitle"
        let originalTitle = "TestTitle"
        let year = "TestYear"
        let duration = "TestDuration"
        let ageRating = "TestAgeRating"
        let genres = ["TestGenre"]
        let plot = "TestPlot"

        Movie.create(
            title: title,
            originalTitle: originalTitle,
            year: year,
            duration: duration,
            ageRating: ageRating,
            genres: genres,
            plot: plot,
            poster: "",
            on: app.db
        )

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

        MovieProfile.create(originalTitle: originalTitle, on: app.db)
        Movie.create(originalTitle: originalTitle, on: app.db)

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

        Movie.create(originalTitle: originalTitle, on: app.db)

        MovieProfile.create(
            title: title,
            originalTitle: originalTitle,
            year: year,
            duration: duration,
            ageRating: ageRating,
            genres: genres,
            plot: plot,
            on: app.db
        )

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

    func testMappingMovieShowings() throws {
        let showing0 = Showing(city: .vilnius)
        let showing1 = Showing(city: .vilnius)
        let showing2 = Showing(city: .vilnius)

        Movie.create(originalTitle: "Movie0", showings: [showing0], on: app.db)
        Movie.create(originalTitle: "Movie1", showings: [showing1], on: app.db)
        Movie.create(originalTitle: "Movie1", showings: [showing2], on: app.db)

        _ = try sut.organize(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        let movie0 = movies.first { $0.originalTitle == "Movie0" }
        let movie1 = movies.first { $0.originalTitle == "Movie1" }

        XCTAssertEqual(movie0?.showings.count, 1)
        XCTAssertEqual(movie1?.showings.count, 2)
    }

    func testCleanup() throws {
        let showing = Showing(city: .vilnius, date: Date(), venue: .forum, is3D: false, url: "")

        Movie.create(originalTitle: "Movie0", showings: [showing], on: app.db)
        Movie.create(originalTitle: "Movie1", showings: [], on: app.db)

        _ = try sut.organize(on: app.db).wait()

        let movies = try Movie.query(on: app.db).all().wait()

        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].originalTitle, "Movie0")
    }

    func testSettingPoster() throws {
        // Located in `Public/Images/Posters`
        let posterFileName = "Example.webp"
        Movie.create(originalTitle: "Example", poster: nil, on: app.db)

        _ = try sut.organize(on: app.db).wait()

        let movie = try Movie.query(on: app.db).first().wait()

        XCTAssertEqual(movie!.poster, "\(Config.apiURL)images/posters/\(posterFileName)")
    }
}
