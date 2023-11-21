//
//  AtlantisTests.swift
//  
//
//  Created by Marius on 2022-12-07.
//

@testable import App
import XCTVapor

final class AtlantisTests: XCTestCase {
    var app: Application!
    var sut: Atlantis!

    override func setUp() {
        app = try! Application.testable()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testFetchingBadResponseThrowsError() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.any(), data: nil)
        sut = Atlantis(client: client)

        XCTAssertThrowsError(try sut.fetchMovies(on: app.db).wait())
    }

    func testFetching() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.any(), data: Data.valid)
        sut = Atlantis(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 2)
        let showings = try Showing.query(on: app.db).all().wait()
        XCTAssertEqual(showings.count, 6)

        XCTAssertEqual(movies[0].title, "Pavadinimas")
        XCTAssertEqual(movies[0].originalTitle, "Title")
        XCTAssertEqual(movies[0].genres, ["Komedija"])
        XCTAssertEqual(movies[0].duration, "110 min")

        XCTAssertEqual(movies[0].showings[0].city, .siauliai)
        XCTAssertEqual(movies[0].showings[0].date, "2023-11-21T13:40:00.000Z".convertToDate())
        XCTAssertEqual(movies[0].showings[0].venue, .atlantis)
        XCTAssertEqual(movies[0].showings[0].is3D, true)
        XCTAssertEqual(movies[0].showings[0].url, "https://www.atlantiscinemas.lt/kasa/seansas/9a9e2093-5cd4-4b4e-8c86-bd8fb568df54")
    }

    func testSkipsShowingIfAPIPropertiesAreMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.any(), data: Data.invalidShowing)
        sut = Atlantis(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 2)
        let showings = try Showing.query(on: app.db).all().wait()
        XCTAssertEqual(showings.count, 4)
    }

    // MARK: Test Helpers

    struct Data {
        static var valid = """
        {
            "data":[
                {
                    "origin_title":"Title",
                    "title":"Pavadinimas",
                    "runtime":110,
                    "genres":[{"title":"Komedija"}],
                    "sessions":[
                        {"uuid":"9a9e2093-5cd4-4b4e-8c86-bd8fb568df54","screening_type":"3d","starts_at":"2023-11-21T13:40:00.000Z"},
                        {"uuid":"9a9e20cc-b191-481c-8a60-5de6d8ba4e48","screening_type":"2d","starts_at":"2023-11-22T13:40:00.000Z"},
                        {"uuid":"9a9e2106-52bb-485c-9cd7-dd43e889529e","screening_type":"2d","starts_at":"2023-11-23T13:40:00.000Z"}
                    ]
                },
                {
                    "origin_title":"Title",
                    "title":"Pavadinimas",
                    "runtime":100,
                    "genres":[{"title":"Drama"},{"title":"Fantastinis"}],
                    "sessions":[
                        {"uuid":"9aa8aab2-f01c-46c8-bdde-56cba2a7a2dd","screening_type":"2d","starts_at":"2023-11-24T16:05:00.000Z"},
                        {"uuid":"9aa8aab2-f93e-4320-bf33-510f73dae92c","screening_type":"2d","starts_at":"2023-11-25T16:05:00.000Z"},
                        {"uuid":"9aa8aab3-016e-4cfa-898d-0dd99d7b84c0","screening_type":"2d","starts_at":"2023-11-26T16:05:00.000Z"}
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        static var invalidShowing = """
        {
            "data":[
                {
                    "origin_title":"Title",
                    "title":"Pavadinimas",
                    "runtime":110,
                    "genres":[{"title":"Komedija"}],
                    "sessions":[
                        {"uuid":"9a9e2093-5cd4-4b4e-8c86-bd8fb568df54","screening_type":"3d","starts_at":"2023-11-21T13:40:00.000Z"},
                        {"uuid":"9a9e20cc-b191-481c-8a60-5de6d8ba4e48","screening_type":"2d","starts_at":"2023-11-22T13:40:00.000Z"},
                        {"uuid":"9a9e2106-52bb-485c-9cd7-dd43e889529e","screening_type":"2d","starts_at":"2023-11-23T13:40:00.000Z"}
                    ]
                },
                {
                    "origin_title":"Title",
                    "title":"Pavadinimas",
                    "runtime":100,
                    "genres":[{"title":"Drama"},{"title":"Fantastinis"}],
                    "sessions":[
                        {"uuid":"9aa8aab2-f01c-46c8-bdde-56cba2a7a2dd","screening_type":"2d","starts_at":""},
                        {"uuid":"9aa8aab2-f93e-4320-bf33-510f73dae92c","screening_type":"2d","starts_at":""},
                        {"uuid":"9aa8aab3-016e-4cfa-898d-0dd99d7b84c0","screening_type":"2d","starts_at":"2023-11-26T16:05:00.000Z"}
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
    }
}
