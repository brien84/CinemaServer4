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

    func testFetchingNoResponseThrowsError() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: .noResponse)
        sut = Multikino(client: client)

        XCTAssertThrowsError(try sut.fetchMovies(on: app.db).wait())
    }

    func testFetchingValidResponse() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: .multikinoValid)
        sut = Multikino(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertGreaterThan(movies.count, 0)
        movies.forEach { XCTAssertGreaterThan($0.showings.count, 0) }
    }

    /// If response contains bad data (missing properties, incorrect values), decoder should ignore it and not throw error.
    func testFetchingBadDataDoesNotThrow() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: .multikinoBadData)
        sut = Multikino(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertGreaterThan(movies.count, 0)
        movies.forEach { XCTAssertGreaterThan($0.showings.count, 0)}
    }
}
