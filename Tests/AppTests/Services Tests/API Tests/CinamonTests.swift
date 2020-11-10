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
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: nil)
        sut = Cinamon(client: client)

        XCTAssertThrowsError(try sut.fetchMovies(on: app.db).wait())
    }

    func testFetching() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.valid)
        sut = Cinamon(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 1)

        XCTAssertEqual(movies[0].title, "title")
        XCTAssertEqual(movies[0].originalTitle, "originalTitle")
        XCTAssertEqual(movies[0].year, "2020")
        XCTAssertEqual(movies[0].duration, "81 min")
        XCTAssertEqual(movies[0].ageRating, "N-7")
        XCTAssertEqual(movies[0].genres, ["Animacinis"])

        XCTAssertEqual(movies[0].showings[0].city, .kaunas)
        XCTAssertEqual(movies[0].showings[0].date, "2020-09-15 10:15:00".convertToDate())
        XCTAssertEqual(movies[0].showings[0].venue, "Cinamon")
        XCTAssertEqual(movies[0].showings[0].is3D, true)
        XCTAssertEqual(movies[0].showings[0].url, "https://cinamonkino.com/mega/seat-plan/1855951372/lt")
    }

    func testSetsMoviePropertiesToNilIfAPIPropertiesAreMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.invalidMovie)
        sut = Cinamon(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 1)

        XCTAssertEqual(movies[0].title, nil)
    }

    func testSkipsShowingIfAPIPropertiesAreMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.invalidShowing)
        sut = Cinamon(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 0)
    }

    func testSkipsMovieIfShowShowingsIfMatchingScreenIsNotFound() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.invalidScreens)
        sut = Cinamon(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 0)
    }

    // MARK: Test Helpers

    struct Data {
        static var valid = """
            {
                "movies": [
                    {
                        "name": "title",
                        "original_name": "originalTitle",
                        "premiere_date": "2020-08-28",
                        "runtime": 81,
                        "rating": "N-7",
                        "genre": {
                            "name": "Animacinis"
                        },

                        "sessions": [
                            {
                                "pid": 1855951372,
                                "screen_name": "Salė 5",
                                "showtime": "2020-09-15 10:15:00",
                                "is_3d": true
                            }
                        ]
                    }
                ],

                "screens": [
                    "Salė 5"
                ]
            }
        """.data(using: .utf8)!

        static var invalidMovie = """
            {
                "movies": [
                    {
                        "name": null,
                        "original_name": "originalTitle",
                        "premiere_date": "2020-08-28",
                        "runtime": 81,
                        "rating": "N-7",
                        "genre": {
                            "name": "Animacinis"
                        },

                        "sessions": [
                            {
                                "pid": 1855951372,
                                "screen_name": "Salė 5",
                                "showtime": "2020-09-15 10:15:00",
                                "is_3d": true
                            }
                        ]
                    }
                ],

                "screens": [
                    "Salė 5"
                ]
            }
        """.data(using: .utf8)!

        static var invalidShowing = """
            {
                "movies": [
                    {
                        "name": null,
                        "original_name": "originalTitle",
                        "premiere_date": "2020-08-28",
                        "runtime": 81,
                        "rating": "N-7",
                        "genre": {
                            "name": "Animacinis"
                        },

                        "sessions": [
                            {
                                "pid": null,
                                "screen_name": "Salė 5",
                                "showtime": "2020-09-15 10:15:00",
                                "is_3d": true
                            }
                        ]
                    }
                ],

                "screens": [
                    "Salė 5"
                ]
            }
        """.data(using: .utf8)!

        static var invalidScreens = """
            {
                "movies": [
                    {
                        "name": null,
                        "original_name": "originalTitle",
                        "premiere_date": "2020-08-28",
                        "runtime": 81,
                        "rating": "N-7",
                        "genre": {
                            "name": "Animacinis"
                        },

                        "sessions": [
                            {
                                "pid": 1855951372,
                                "screen_name": "Salė 5",
                                "showtime": "2020-09-15 10:15:00",
                                "is_3d": true
                            }
                        ]
                    }
                ],

                "screens": [
                    "Salė 69"
                ]
            }
        """.data(using: .utf8)!
    }
}
