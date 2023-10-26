//
//  ContentValidatorTests.swift
//
//
//  Created by Marius on 2020-10-28.
//

@testable import App
import XCTVapor

final class ContentValidatorTests: XCTestCase {
    var app: Application!
    var sut: ContentValidator!

    override func setUp() {
        app = try! Application.testable()
        sut = ContentValidator()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testMovieWithValidDataPassesValidation() throws {
        Movie.create(
            title: "test",
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: .v,
            genres: ["test"],
            plot: "test",
            poster: "test",
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 1)
    }

    func testEmptyStringTriggersValidator() throws {
        Movie.create(
            title: "",
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: .v,
            genres: ["test"],
            plot: "test",
            poster: "test",
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingTitleProperty() throws {
        Movie.create(
            title: nil,
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: .v,
            genres: ["test"],
            plot: "test",
            poster: "test",
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingOriginalTitleProperty() throws {
        Movie.create(
            title: "test",
            originalTitle: nil,
            year: "test",
            duration: "test",
            ageRating: .v,
            genres: ["test"],
            plot: "test",
            poster: "test",
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingYearProperty() throws {
        Movie.create(
            title: "test",
            originalTitle: "test",
            year: nil,
            duration: "test",
            ageRating: .v,
            genres: ["test"],
            plot: "test",
            poster: "test",
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingDurationProperty() throws {
        Movie.create(
            title: "test",
            originalTitle: "test",
            year: "test",
            duration: nil,
            ageRating: .v,
            genres: ["test"],
            plot: "test",
            poster: "test",
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingAgeRatingProperty() throws {
        Movie.create(
            title: "test",
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: nil,
            genres: ["test"],
            plot: "test",
            poster: "test",
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingGenresProperty() throws {
        Movie.create(
            title: "test",
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: .v,
            genres: [],
            plot: "test",
            poster: "test",
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingPlotProperty() throws {
        Movie.create(
            title: "test",
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: .v,
            genres: ["test"],
            plot: nil,
            poster: "test",
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingPosterProperty() throws {
        Movie.create(
            title: "test",
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: .v,
            genres: ["test"],
            plot: "test",
            poster: nil,
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testValidatingShowingsProperty() throws {
        Movie.create(
            title: "test",
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: .v,
            genres: ["test"],
            plot: "test",
            poster: "test",
            showings: [],
            on: app.db
        )

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
        Movie.create(
            title: "test",
            originalTitle: nil,
            year: "test",
            duration: "test",
            ageRating: "test",
            genres: ["test"],
            plot: "test",
            poster: "test",
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertEqual(report, "<p>Movies failed validation: </p>" + "<p>Movie is missing originalTitle.</p>")
    }

    func testFailedValidationReportContainsOriginalTitleAndURL() throws {
        let originalTitle = "title"
        let url = "url"

        let showing = Showing(city: .vilnius, url: url)

        Movie.create(originalTitle: originalTitle, showings: [showing], on: app.db)

        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertTrue(report.contains(originalTitle))
        XCTAssertTrue(report.contains(url))
    }

    func testReportIsSortedByEarliestShowings() throws {
        let now = Date()

        Movie.create(
            originalTitle: "Movie A",
            showings: [
                Showing(date: now.advanced(by: 30), url: "URL-A1"),
                Showing(date: now.advanced(by: 20), url: "URL-A2"),
                Showing(date: now.advanced(by: 10), url: "URL-A3")
            ],
            on: app.db
        )

        Movie.create(
            originalTitle: "Movie B",
            showings: [
                Showing(date: now.advanced(by: 0), url: "URL-B1"),
                Showing(date: now.advanced(by: 10), url: "URL-B2"),
                Showing(date: now.advanced(by: 20), url: "URL-B3")
            ],
            on: app.db
        )

        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertEqual(
            report,
            "<p>Movies failed validation: </p>" +
            "<p><a href=\"URL-B1\">Movie B | \(now.advanced(by: 0).formatted)</a></p>" +
            "<p><a href=\"URL-A3\">Movie A | \(now.advanced(by: 10).formatted)</a></p>"
        )
    }

    func testMoviesArrayIsClearedWhenValidationStarts() throws {
        let originalTitle0 = "title0"
        let originalTitle1 = "title1"

        Movie.create(originalTitle: originalTitle0, on: app.db)
        try sut.validate(on: app.db).wait()

        Movie.create(originalTitle: originalTitle1, on: app.db)
        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertFalse(report.contains(originalTitle0))
        XCTAssertTrue(report.contains(originalTitle1))
    }
}
