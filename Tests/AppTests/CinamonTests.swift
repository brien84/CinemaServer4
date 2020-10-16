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

    func testFetchingNoResponseThrowsError() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: .noResponse)
        sut = Cinamon(client: client, database: app.db)

        XCTAssertThrowsError(try sut.fetchMovies().wait())
    }

    func testFetchingValidResponse() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: .cinamonValid)
        sut = Cinamon(client: client, database: app.db)

        try sut.fetchMovies().wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertGreaterThan(movies.count, 0)
        movies.forEach { XCTAssertGreaterThan($0.showings.count, 0) }
    }

    /// If response contains bad data (missing properties, incorrect values), decoder should ignore it and not throw error.
    func testFetchingBadDataDoesNotThrow() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: .cinamonBadData)
        sut = Cinamon(client: client, database: app.db)

        try sut.fetchMovies().wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertGreaterThan(movies.count, 0)
        movies.forEach { XCTAssertGreaterThan($0.showings.count, 0) }
    }
}

