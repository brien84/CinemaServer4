//
//  ApolloTests.swift
//  
//
//  Created by Marius on 2022-11-16.
//

@testable import App
import XCTVapor

final class ApolloTests: XCTestCase {
    var app: Application!
    var sut: Apollo!

    override func setUp() {
        app = try! Application.testable()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testFetchingBadResponseThrowsError() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: nil)
        sut = Apollo(client: client)

        XCTAssertThrowsError(try sut.fetchMovies(on: app.db).wait())
    }

    func testFetching() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.valid)
        sut = Apollo(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 2)

        XCTAssertEqual(movies[0].title, "title")
        XCTAssertEqual(movies[0].originalTitle, "originalTitle")
        XCTAssertEqual(movies[0].year, "2020")
        XCTAssertEqual(movies[0].duration, "98 min")
        XCTAssertEqual(movies[0].ageRating, "N-7")
        XCTAssertEqual(movies[0].genres, ["Animacinis", "Drama"])

        XCTAssertEqual(movies[0].showings.filter { $0.city == .panevezys }.count, 1)
        XCTAssertEqual(movies[0].showings.filter { $0.city == .vilnius }.count, 1)
        XCTAssertEqual(movies[0].showings[0].date, "2022-11-16T10:30:00".convertToDate())
        XCTAssertEqual(movies[0].showings[0].venue, "Apollo")
        XCTAssertEqual(movies[0].showings[0].is3D, true)
        XCTAssertEqual(movies[0].showings[0].url, "https://www.apollokinas.lt/websales/show/305193")
    }

    func testSetsMoviePropertiesToNilIfAPIPropertiesAreMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.invalidMovie)
        sut = Apollo(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)

        XCTAssertEqual(movies[0].title, nil)
        XCTAssertEqual(movies[0].year, nil)
        XCTAssertEqual(movies[0].duration, nil)
        XCTAssertEqual(movies[0].ageRating, nil)
        XCTAssertEqual(movies[0].genres, nil)
    }

    func testSkipsShowingIfAPIPropertiesAreMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.invalidShowing)
        sut = Apollo(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].showings.count, 0)
    }

    // MARK: Test Helpers

    struct Data {
        static var valid = """
            {
                "Shows":[
                    {
                        "Title": "title",
                        "OriginalTitle": "originalTitle",
                        "ProductionYear": 2020,
                        "LengthInMinutes": 98,
                        "RatingLabel": "N7",
                        "Genres": "animacinis, drama",
                        "dttmShowStart": "2022-11-16T10:30:00",
                        "Theatre": "Apollo",
                        "PresentationMethod": "3D",
                        "ShowURL": "https://www.apollokinas.lt/websales/show/305193"
                    }
                ]
            }
        """.data(using: .utf8)!

        static var invalidMovie = """
             {
                 "Shows":[
                     {
                         "Title": null,
                         "OriginalTitle": "originalTitle",
                         "ProductionYear": null,
                         "LengthInMinutes": null,
                         "RatingLabel": null,
                         "Genres": null,
                         "dttmShowStart": "2022-11-16T10:30:00",
                         "Theatre": "Apollo",
                         "PresentationMethod": "3D",
                         "ShowURL": "https://www.apollokinas.lt/websales/show/305193"
                     }
                 ]
             }
        """.data(using: .utf8)!

        static var invalidShowing = """
            {
                "Shows":[
                    {
                        "Title": "title",
                        "OriginalTitle": "originalTitle",
                        "ProductionYear": 2020,
                        "LengthInMinutes": 98,
                        "RatingLabel": "N7",
                        "Genres": "animacinis, drama",
                        "dttmShowStart": null,
                        "Theatre": "Apollo",
                        "PresentationMethod": "3D",
                        "ShowURL": "https://www.apollokinas.lt/websales/show/305193"
                    }
                ]
            }
        """.data(using: .utf8)!
    }
}

