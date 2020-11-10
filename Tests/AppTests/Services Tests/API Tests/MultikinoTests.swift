//
//  MultikinoTests.swift
//
//
//  Created by Marius on 2020-09-26.
//

@testable import App
import XCTVapor

final class MultikinoTests: XCTestCase {
    var app: Application!
    var sut: Multikino!

    override func setUp() {
        app = try! Application.testable()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testFetchingBadResponseThrowsError() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: nil)
        sut = Multikino(client: client)

        XCTAssertThrowsError(try sut.fetchMovies(on: app.db).wait())
    }

    func testFetching() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.valid)
        sut = Multikino(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 1)

        XCTAssertEqual(movies[0].title, "title")
        XCTAssertEqual(movies[0].originalTitle, "originalTitle")
        XCTAssertEqual(movies[0].year, "2020")
        XCTAssertEqual(movies[0].duration, "119 min")
        XCTAssertEqual(movies[0].ageRating, "N-13")
        XCTAssertEqual(movies[0].genres, ["Trileris", "Veiksmo"])

        XCTAssertEqual(movies[0].showings[0].city, .vilnius)
        XCTAssertEqual(movies[0].showings[0].date, "2020-10-01T21:45:00".convertToDate())
        XCTAssertEqual(movies[0].showings[0].venue, "Multikino")
        XCTAssertEqual(movies[0].showings[0].is3D, true)
        XCTAssertEqual(movies[0].showings[0].url, "https://multikino.lt/pirkti-bilieta/santrauka/1001/3015/139426")
    }

    func testSetsMoviePropertiesToNilIfAPIPropertiesAreMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.invalidMovie)
        sut = Multikino(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 1)

        XCTAssertEqual(movies[0].ageRating, nil)
    }

    func testSkipsShowingIfAPIPropertiesAreMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.invalidShowing)
        sut = Multikino(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 0)
    }

    func testSkipsMovieIfShowShowingsIsFalse() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.showShowingsIsFalse)
        sut = Multikino(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 0)
    }

    // MARK: Test Helpers

    struct Data {
        static var valid = """
            {
                "films": [
                    {
                        "title": "title (originalTitle)",
                        "info_release": "14.08.2020",
                        "info_runningtime": "119 min.",
                        "info_age": "N-13",
                        "genres": {
                            "names": [
                                {
                                    "name": "Trileris"
                                },
                                {
                                    "name": "Veiksmo"
                                }
                            ]
                        },
                        "show_showings": true,
                        "showings": [
                            {
                                "times": [
                                    {
                                        "date": "2020-10-01T21:45:00",
                                        "link": "/pirkti-bilieta/santrauka/1001/3015/139426",
                                        "screen_type": "3D"
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        """.data(using: .utf8)!

        static var invalidMovie = """
            {
                "films": [
                    {
                        "title": "title (originalTitle)",
                        "info_release": "14.08.2020",
                        "info_runningtime": "119 min.",
                        "info_age": null,
                        "genres": {
                            "names": [
                                {
                                    "name": "Trileris"
                                },
                                {
                                    "name": "Veiksmo"
                                }
                            ]
                        },
                        "show_showings": true,
                        "showings": [
                            {
                                "times": [
                                    {
                                        "date": "2020-10-01T21:45:00",
                                        "link": "/pirkti-bilieta/santrauka/1001/3015/139426",
                                        "screen_type": "3D"
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        """.data(using: .utf8)!

        static var invalidShowing = """
            {
                "films": [
                    {
                        "title": "title (originalTitle)",
                        "info_release": "14.08.2020",
                        "info_runningtime": "119 min.",
                        "info_age": "N-13",
                        "genres": {
                            "names": [
                                {
                                    "name": "Trileris"
                                },
                                {
                                    "name": "Veiksmo"
                                }
                            ]
                        },
                        "show_showings": true,
                        "showings": [
                            {
                                "times": [
                                    {
                                        "date": null,
                                        "link": "/pirkti-bilieta/santrauka/1001/3015/139426",
                                        "screen_type": "3D"
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        """.data(using: .utf8)!

        static var showShowingsIsFalse = """
            {
                "films": [
                    {
                        "title": "title (originalTitle)",
                        "info_release": "14.08.2020",
                        "info_runningtime": "119 min.",
                        "info_age": "N-13",
                        "genres": {
                            "names": [
                                {
                                    "name": "Trileris"
                                },
                                {
                                    "name": "Veiksmo"
                                }
                            ]
                        },
                        "show_showings": false,
                        "showings": [
                            {
                                "times": [
                                    {
                                        "date": "2020-10-01T21:45:00",
                                        "link": "/pirkti-bilieta/santrauka/1001/3015/139426",
                                        "screen_type": "3D"
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        """.data(using: .utf8)!
    }
}
