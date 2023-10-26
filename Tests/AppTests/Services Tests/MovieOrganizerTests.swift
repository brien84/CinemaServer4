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
        let ageRating = AgeRating.v
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
        let originalTitle = "Example"
        let year = "TestYear"
        let duration = "TestDuration"
        let ageRating = AgeRating.v
        let genres = ["TestGenre"]
        let plot = "TestPlot"
        let posterFile = "\(originalTitle).webp"
        let posterURL = Assets.posters.url.appendingPathComponent(posterFile).absoluteString

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
        XCTAssertEqual(movies[0].poster, posterURL)
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

    func testMappingFeatured() throws {
        let featured = Featured.create(id: UUID(), label: "test", title: "test", originalTitle: "Example", on: app.db)
        let imageFile = "\(featured.originalTitle).webp"
        let imageURL = Assets.featured.url.appendingPathComponent(imageFile).absoluteString
        Movie.create(originalTitle: "Example", on: app.db)

        _ = try sut.organize(on: app.db).wait()

        let allFeatured = try Featured.query(on: app.db).with(\.$movie).all().wait()
        let movie = try Movie.query(on: app.db).first().wait()

        XCTAssertEqual(allFeatured.count, 1)
        XCTAssertEqual(allFeatured[0].label, featured.label)
        XCTAssertEqual(allFeatured[0].title, featured.title)
        XCTAssertEqual(allFeatured[0].originalTitle, featured.originalTitle)
        XCTAssertEqual(allFeatured[0].startDate, featured.startDate)
        XCTAssertEqual(allFeatured[0].endDate, featured.endDate)
        XCTAssertEqual(allFeatured[0].imageURL, imageURL)
        XCTAssertEqual(allFeatured[0].movie?.id, movie!.id)
    }
}
