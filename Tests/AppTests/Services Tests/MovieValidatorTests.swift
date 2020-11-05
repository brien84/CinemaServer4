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

    func testReportContentWhenAllMoviesPassValidation() throws {
        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertEqual(report, "<p>All movies passed validation!</p>")
    }

    func testReportContentWhenOriginalTitleIsMissing() throws {
        Movie.create(title: "test", originalTitle: nil, year: "test", duration: "test",
                                 ageRating: "test", genres: ["test"], plot: "test", poster: "test", on: app.db)

        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertEqual(report, "<p>Movies failed validation: </p>" + "<p>Movie is missing originalTitle.</p>")
    }

    func testFailedValidationReportContainsOriginalTitleAndURL() throws {
        let originalTitle = "title"
        let url = "url"

        let showing = Showing(city: "", date: Date(), venue: "", is3D: false, url: url)
        Movie.create(title: "", originalTitle: originalTitle, year: "", duration: "",
                     ageRating: "", genres: [], plot: "", poster: "", showings: [showing], on: app.db)

        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertTrue(report.contains(originalTitle))
        XCTAssertTrue(report.contains(url))
    }

    func testMoviesArrayIsClearedWhenValidationStarts() throws {
        let originalTitle0 = "title0"
        let originalTitle1 = "title1"

        Movie.create(title: "", originalTitle: originalTitle0, year: "", duration: "",
                     ageRating: "", genres: [], plot: "", poster: "", on: app.db)

        try sut.validate(on: app.db).wait()

        Movie.create(title: "", originalTitle: originalTitle1, year: "", duration: "",
                     ageRating: "", genres: [], plot: "", poster: "", on: app.db)

        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertFalse(report.contains(originalTitle0))
        XCTAssertTrue(report.contains(originalTitle1))
    }
}
