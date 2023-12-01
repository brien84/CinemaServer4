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

    func testFeaturedWithValidDataPassesValidation() throws {
        let movie = Movie(
            title: "test",
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: .v,
            genres: ["test"],
            plot: "test",
            poster: "test"
        )

        let featured = Featured(
            id: UUID(),
            label: "test",
            title: "test",
            originalTitle: "test",
            startDate: Date(),
            endDate: Date(),
            imageURL: "test"
        )

        _ = try! movie.create(on: app.db).wait()
        _ = try! movie.$showings.create([Showing(city: .vilnius)], on: app.db).wait()
        _ = try! movie.$featured.create(featured, on: app.db).wait()

        try sut.validate(on: app.db).wait()

        let movieID = try! Featured.query(on: app.db).with(\.$movie).first().wait()?.$movie.id
        XCTAssertNotEqual(movieID, nil)
    }

    func testFeaturedWithInvalidDataTriggersValidation() throws {
        let movie = Movie(
            title: "test",
            originalTitle: "test",
            year: "test",
            duration: "test",
            ageRating: .v,
            genres: ["test"],
            plot: "test",
            poster: "test"
        )

        let featured = Featured(
            id: UUID(),
            label: "",
            title: "test",
            originalTitle: "test",
            startDate: Date(),
            endDate: Date(),
            imageURL: "test"
        )

        _ = try! movie.create(on: app.db).wait()
        _ = try! movie.$featured.create(featured, on: app.db).wait()

        try sut.validate(on: app.db).wait()

        let movieID = try! Featured.query(on: app.db).with(\.$movie).first().wait()?.$movie.id
        XCTAssertEqual(movieID, nil)
    }

    func testNilPropertyThrowsValidationError() throws {
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

    func testEmptyStringThrowsValidationError() throws {
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

    func testEmptyStringArrayThrowsValidationError() throws {
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

    func testEmptyShowingsArrayThrowsValidationError() throws {
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

    func testReportContentWhenAllContentPassValidation() throws {
        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertEqual(
            report,
            "<p>All movies passed validation!</p><p>-----</p><p>All featured passed validation!</p>"
        )
    }

    func testMovieReportContentWhenOriginalTitleIsMissing() throws {
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

        let report = sut.getMovieReport()
        XCTAssertEqual(
            report,
            "<p>Movies failed validation: </p>" + "<p>Movie is missing originalTitle.</p>"
        )
    }

    func testFailedMovieValidationReportContainsOriginalTitleAndURL() throws {
        let originalTitle = "title"
        let url = "url"

        let showing = Showing(city: .vilnius, url: url)
        Movie.create(originalTitle: originalTitle, showings: [showing], on: app.db)

        try sut.validate(on: app.db).wait()

        let report = sut.getReport()
        XCTAssertTrue(report.contains(originalTitle))
        XCTAssertTrue(report.contains(url))
    }

    func testMovieReportIsSortedByEarliestShowings() throws {
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

        let report = sut.getMovieReport()
        XCTAssertEqual(
            report,
            "<p>Movies failed validation: </p>" +
            "<p><a href=\"URL-B1\">Movie B | \(now.advanced(by: 0).formatted)</a></p>" +
            "<p><a href=\"URL-A3\">Movie A | \(now.advanced(by: 10).formatted)</a></p>"
        )
    }

    func testValidationReportResetsValidationStarts() throws {
        let originalTitle0 = "title0"
        let originalTitle1 = "title1"

        Movie.create(originalTitle: originalTitle0, on: app.db)
        try sut.validate(on: app.db).wait()

        let report0 = sut.getReport()
        XCTAssertTrue(report0.contains(originalTitle0))
        XCTAssertFalse(report0.contains(originalTitle1))

        Movie.create(originalTitle: originalTitle1, on: app.db)
        try sut.validate(on: app.db).wait()

        let report1 = sut.getReport()
        XCTAssertFalse(report1.contains(originalTitle0))
        XCTAssertTrue(report1.contains(originalTitle1))
    }
}

private extension ContentValidator {
    func getFeaturedReport() -> String? {
        self.getReport().slice(from: "<p>-----</p>", to: nil, isSlicingBackwards: true)
    }

    func getMovieReport() -> String? {
        self.getReport().slice(from: nil, to: "<p>-----</p>")
    }
}
