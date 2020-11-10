//
//  ForumCinemasTests.swift
//
//
//  Created by Marius on 2020-09-26.
//

@testable import App
import XCTVapor

final class ForumCinemasTests: XCTestCase {
    var app: Application!
    var sut: ForumCinemas!

    override func setUp() {
        app = try! Application.testable()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testFetchingBadResponseThrowsError() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: nil)
        sut = ForumCinemas(client: client)

        XCTAssertThrowsError(try sut.fetchMovies(on: app.db).wait())
    }

    func testFetching() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.valid)
        sut = ForumCinemas(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 1)

        XCTAssertEqual(movies[0].title, "title")
        XCTAssertEqual(movies[0].originalTitle, "originalTitle")
        XCTAssertEqual(movies[0].year, "2020")
        XCTAssertEqual(movies[0].duration, "103 min")
        XCTAssertEqual(movies[0].ageRating, "N-16")
        XCTAssertEqual(movies[0].genres, ["Trileris", "Fantastinis"])

        XCTAssertEqual(movies[0].showings[0].city, .vilnius)
        XCTAssertEqual(movies[0].showings[0].date, "2020-09-26T21:00:00".convertToDate())
        XCTAssertEqual(movies[0].showings[0].venue, "Forum Cinemas Akropolis")
        XCTAssertEqual(movies[0].showings[0].is3D, false)
        XCTAssertEqual(movies[0].showings[0].url, "https://m.forumcinemas.lt/Websales/Show/790854/")
    }

    func testFetchingFromAllAreas() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.allAreas)
        sut = ForumCinemas(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 4)

        let cities = movies[0].showings.map { $0.city }

        XCTAssertTrue(cities.contains(.vilnius))
        XCTAssertTrue(cities.contains(.kaunas))
        XCTAssertTrue(cities.contains(.klaipeda))
        XCTAssertTrue(cities.contains(.siauliai))
    }

    func testSetsMoviePropertiesToNilIfAPIPropertiesAreMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.invalidMovie)
        sut = ForumCinemas(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 1)

        XCTAssertEqual(movies[0].title, nil)
    }

    func testSkipsShowingIfAPIPropertiesAreMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.invalidShowing)
        sut = ForumCinemas(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 0)
    }

    // MARK: Test Helpers

    struct Data {
        static var valid = """
            {
                "TheatreAreas": [
                    {
                        "ID": 1011,
                        "Name": "Vilnius"
                    }
                ],

                "Shows": [
                    {
                        "Title": "title",
                        "OriginalTitle": "originalTitle",
                        "ProductionYear": 2020,
                        "LengthInMinutes": 103,
                        "RatingLabel": "N16",
                        "Genres": "Trileris, Fantastinis",
                        "dttmShowStart": "2020-09-26T21:00:00",
                        "Theatre": "Forum Cinemas Akropolis (Vilniuje)",
                        "ShowURL": "http://m.forumcinemas.lt/Websales/Show/790854/"
                    }
                ]
            }
        """.data(using: .utf8)!

        static var allAreas = """
            {
                "TheatreAreas": [
                    {
                        "ID": 1011,
                        "Name": "Vilnius"
                    },
                    {
                        "ID": 1012,
                        "Name": "Kaunas"
                    },
                    {
                        "ID": 1015,
                        "Name": "Klaipėda"
                    },
                    {
                        "ID": 1014,
                        "Name": "Šiauliai"
                    }
                ],

                "Shows": [
                    {
                        "Title": "title",
                        "OriginalTitle": "originalTitle",
                        "ProductionYear": 2020,
                        "LengthInMinutes": 103,
                        "RatingLabel": "N16",
                        "Genres": "Trileris, Fantastinis",
                        "dttmShowStart": "2020-09-26T21:00:00",
                        "Theatre": "Forum Cinemas Akropolis (Vilniuje)",
                        "ShowURL": "http://m.forumcinemas.lt/Websales/Show/790854/"
                    }
                ]
            }
        """.data(using: .utf8)!

        static var invalidMovie = """
            {
                "TheatreAreas": [
                    {
                        "ID": 1011,
                        "Name": "Vilnius"
                    }
                ],

                "Shows": [
                    {
                        "Title": null,
                        "OriginalTitle": "originalTitle",
                        "ProductionYear": 2020,
                        "LengthInMinutes": 103,
                        "RatingLabel": "N16",
                        "Genres": "Trileris, Fantastinis",
                        "dttmShowStart": "2020-09-26T21:00:00",
                        "Theatre": "Forum Cinemas Akropolis (Vilniuje)",
                        "ShowURL": "http://m.forumcinemas.lt/Websales/Show/790854/"
                    }
                ]
            }
        """.data(using: .utf8)!

        static var invalidShowing = """
            {
                "TheatreAreas": [
                    {
                        "ID": 1011,
                        "Name": "Vilnius"
                    }
                ],

                "Shows": [
                    {
                        "Title": "title",
                        "OriginalTitle": "originalTitle",
                        "ProductionYear": 2020,
                        "LengthInMinutes": 103,
                        "RatingLabel": "N16",
                        "Genres": "Trileris, Fantastinis",
                        "dttmShowStart": "2020-09-26T21:00:00",
                        "Theatre": null,
                        "ShowURL": "http://m.forumcinemas.lt/Websales/Show/790854/"
                    }
                ]
            }
        """.data(using: .utf8)!
    }
}
