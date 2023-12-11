//
//  CinamonTests.swift
//  
//
//  Created by Marius on 2020-09-13.
//

@testable import App
import XCTVapor

final class CinamonTests: XCTestCase {
    var app: Application!
    var sut: Cinamon!

    override func setUp() {
        app = try! Application.testable()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testFetchingBadResponseThrowsError() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.any(), data: nil)
        sut = Cinamon(client: client)

        XCTAssertThrowsError(try sut.fetchMovies(on: app.db).wait())
    }

    func testFetching() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.any()) { request in
            if request.url.string.contains("page") {
                return Data.dates
            }

            return Data.valid
        }

        sut = Cinamon(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 1)

        XCTAssertEqual(movies[0].title, "title")
        XCTAssertEqual(movies[0].originalTitle, "originalTitle")
        XCTAssertEqual(movies[0].duration, "81 min")
        XCTAssertEqual(movies[0].ageRating, .n7)
        XCTAssertEqual(movies[0].genres, ["Animacinis"])

        XCTAssertEqual(movies[0].showings[0].city, .kaunas)
        XCTAssertEqual(movies[0].showings[0].date, "2020-09-15 10:15:00".convertToDate())
        XCTAssertEqual(movies[0].showings[0].venue, .cinamon)
        XCTAssertEqual(movies[0].showings[0].is3D, true)
        XCTAssertEqual(movies[0].showings[0].url, "https://cinamonkino.com/mega/seat-plan/140593226/lt")
    }

    func testMovieIsSkippedIfWebSalesAreNotAllowed() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.any()) { request in
            if request.url.string.contains("page") {
                return Data.dates
            }

            return Data.noWebSales
        }

        sut = Cinamon(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 0)
    }

    // MARK: Test Helpers

    struct Data {
        static var dates = """
        {
            "calendar_dates": [
                "2023-12-11"
            ]
        }
        """.data(using: .utf8)!

        static var valid = """
            [
                {
                    "pid": 140593226,
                    "showtime": "2020-09-15 10:15:00",
                    "allow_web_sales": 1,
                    "is_3d": true,
                    "film": {
                        "pid": 622191926,
                        "name": "title",
                        "original_name": "originalTitle",
                        "runtime": 81,
                        "rating": "N-7",
                        "genre": { "name": "Animacinis" }
                    }
                }
            ]
        """.data(using: .utf8)!

        static var noWebSales = """
            [
                {
                    "pid": 140593226,
                    "showtime": "2020-09-15 10:15:00",
                    "allow_web_sales": 0,
                    "is_3d": true,
                    "film": {
                        "pid": 622191926,
                        "name": "title",
                        "original_name": "originalTitle",
                        "runtime": 81,
                        "rating": "N-7",
                        "genre": { "name": "Animacinis" }
                    }
                }
            ]
        """.data(using: .utf8)!
    }
}
