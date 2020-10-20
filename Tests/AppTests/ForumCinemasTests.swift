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

    /// `getAreas()` method should throw.
    func testFetchingNoResponseThrowsError() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: .noResponse)
        sut = ForumCinemas(client: client, database: app.db)

        XCTAssertThrowsError(try sut.fetchMovies().wait())
    }

    /// `forumCinemasNoShowings` test data only contains a valid list of areas, so
    /// `getForumShowings(in area: Area)`  method should throw.
    func testFetchingNoShowingsResponseThrowsError() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: .forumCinemasNoShowings)
        sut = ForumCinemas(client: client, database: app.db)

        XCTAssertThrowsError(try sut.fetchMovies().wait())
    }

    func testFetchingValidResponse() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: .forumCinemasValid)
        sut = ForumCinemas(client: client, database: app.db)

        try sut.fetchMovies().wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertGreaterThan(movies.count, 0)
        movies.forEach { XCTAssertGreaterThan($0.showings.count, 0) }
    }

    /// If response contains bad data (missing properties, incorrect values), decoder should ignore it and not throw error.
    func testFetchingBadDataDoesNotThrow() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: .forumCinemasBadData)
        sut = ForumCinemas(client: client, database: app.db)

        try sut.fetchMovies().wait()
        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertGreaterThan(movies.count, 0)
    }
}
