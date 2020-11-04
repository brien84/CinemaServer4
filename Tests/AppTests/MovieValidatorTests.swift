//
//  MovieValidatorTests.swift
//
//
//  Created by Marius on 2020-10-28.
//

@testable import App
import XCTVapor

final class MovieValidatorTests: XCTestCase {
    var app: Application!
    var sut: MovieValidator!

    override func setUp() {
        app = try! Application.testable()
        sut = MovieValidator()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testMovieWithValidDataPassesValidation() throws {
        Movie.create(title: "test", originalTitle: "test", year: "test", duration: "test",
                     ageRating: "test", genres: ["test"], plot: "test", poster: "test", on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 1)
    }

    func testEmptyStringTriggersValidator() throws {
        Movie.create(title: "", originalTitle: "test", year: "test", duration: "test",
                     ageRating: "test", genres: ["test"], plot: "test", poster: "test", on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingTitleProperty() throws {
        Movie.create(title: nil, originalTitle: "test", year: "test", duration: "test",
                     ageRating: "test", genres: ["test"], plot: "test", poster: "test", on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingOriginalTitleProperty() throws {
        Movie.create(title: "test", originalTitle: nil, year: "test", duration: "test",
                     ageRating: "test", genres: ["test"], plot: "test", poster: "test", on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingYearProperty() throws {
        Movie.create(title: "test", originalTitle: "test", year: nil, duration: "test",
                     ageRating: "test", genres: ["test"], plot: "test", poster: "test", on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingDurationProperty() throws {
        Movie.create(title: "test", originalTitle: "test", year: "test", duration: nil,
                     ageRating: "test", genres: ["test"], plot: "test", poster: "test", on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingAgeRatingProperty() throws {
        Movie.create(title: "test", originalTitle: "test", year: "test", duration: "test",
                     ageRating: nil, genres: ["test"], plot: "test", poster: "test", on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingGenresProperty() throws {
        Movie.create(title: "test", originalTitle: "test", year: "test", duration: "test",
                     ageRating: "test", genres: [], plot: "test", poster: "test", on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingPlotProperty() throws {
        Movie.create(title: "test", originalTitle: "test", year: "test", duration: "test",
                     ageRating: "test", genres: ["test"], plot: nil, poster: "test", on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingPosterProperty() throws {
        Movie.create(title: "test", originalTitle: "test", year: "test", duration: "test",
                     ageRating: "test", genres: ["test"], plot: "test", poster: nil, on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingShowingsProperty() throws {
        Movie.create(title: "test", originalTitle: "test", year: "test", duration: "test",
                     ageRating: "test", genres: ["test"], plot: "test", poster: "test", showings: [], on: app.db)

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }
}
