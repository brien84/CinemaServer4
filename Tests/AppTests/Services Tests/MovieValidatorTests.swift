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
        Movie.create(
            title: "test",
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: "test",
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
            ageRating: "test",
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
            ageRating: "test",
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
            ageRating: "test",
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
            ageRating: "test",
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
            ageRating: "test",
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
            ageRating: "test",
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
            ageRating: "test",
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
            ageRating: "test",
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
            ageRating: "test",
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

    func testReportIsSorted() throws {
        Movie.create(originalTitle: "ZZZ", on: app.db)
        Movie.create(originalTitle: "AAB", on: app.db)
        Movie.create(originalTitle: nil, on: app.db)
        Movie.create(originalTitle: "AAA", on: app.db)

        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertEqual(report, "<p>Movies failed validation: </p>" +
                               "<p><a href=\"\">AAA</a></p>" +
                               "<p><a href=\"\">AAB</a></p>" +
                               "<p><a href=\"\">ZZZ</a></p>" +
                               "<p>Movie is missing originalTitle.</p>")
    }

    func testReporterPicksForumCinemasShowingURL() throws {
        let apolloURL = "https://www.apollokinas.lt/websales/show/305141"
        let atlantisURL = "https://www.atlantiscinemas.lt/velnio-sviesa?sdate=1670284800"
        let cinamonURL = "https://cinamonkino.com/mega/seat-plan/190310353/lt"
        let forumURL = "https://m.forumcinemas.lt/Websales/Show/797892/"
        let multikinoURL = "https://multikino.lt/pirkti-bilieta/santrauka/1001/3078/140713"

        let apolloShowing = Showing(city: .panevezys, url: apolloURL)
        let atlantisShowing = Showing(city: .siauliai, url: atlantisURL)
        let cinamonShowing = Showing(city: .vilnius, url: cinamonURL)
        let forumShowing = Showing(city: .vilnius, url: forumURL)
        let multiShowing = Showing(city: .vilnius, url: multikinoURL)

        Movie.create(
            originalTitle: "test",
            showings: [apolloShowing, atlantisShowing, cinamonShowing, forumShowing, multiShowing],
            on: app.db
        )

        try sut.validate(on: app.db).wait()
        let report = sut.getReport()
        XCTAssertTrue(report.contains(forumURL))
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
