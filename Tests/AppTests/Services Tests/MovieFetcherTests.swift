//
//  MovieFetcherTests.swift
//
//
//  Created by Marius on 2020-09-26.
//

@testable import App
import Fluent
import XCTVapor

final class MovieFetcherTests: XCTestCase {
    var app: Application!
    var sut: MovieFetcher!

    override func setUp() {
        app = try! Application.testable()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testFetchingDoesNotThrowWhenAllServicesSucceed() throws {
        sut = MovieFetcher(
            apollo: TestAPI(true),
            atlantis: TestAPI(true),
            cinamon: TestAPI(true),
            forum: TestAPI(true),
            multikino: TestAPI(true)
        )

        try sut.fetch(on: app.db).wait()
    }

    func testFetchingThrowsWhenApolloFails() throws {
        sut = MovieFetcher(
            apollo: TestAPI(false),
            atlantis: TestAPI(true),
            cinamon: TestAPI(true),
            forum: TestAPI(true),
            multikino: TestAPI(true)
        )

        XCTAssertThrowsError(try sut.fetch(on: app.db).wait())
    }

    func testFetchingThrowsWhenAtlantisFails() throws {
        sut = MovieFetcher(
            apollo: TestAPI(true),
            atlantis: TestAPI(false),
            cinamon: TestAPI(true),
            forum: TestAPI(true),
            multikino: TestAPI(true)
        )

        XCTAssertThrowsError(try sut.fetch(on: app.db).wait())
    }

    func testFetchingThrowsWhenCinamonFails() throws {
        sut = MovieFetcher(
            apollo: TestAPI(true),
            atlantis: TestAPI(true),
            cinamon: TestAPI(false),
            forum: TestAPI(true),
            multikino: TestAPI(true)
        )

        XCTAssertThrowsError(try sut.fetch(on: app.db).wait())
    }

    func testFetchingThrowsWhenForumFails() throws {
        sut = MovieFetcher(
            apollo: TestAPI(true),
            atlantis: TestAPI(true),
            cinamon: TestAPI(true),
            forum: TestAPI(false),
            multikino: TestAPI(true)
        )

        XCTAssertThrowsError(try sut.fetch(on: app.db).wait())
    }

    func testFetchingThrowsWhenMultikinoFails() throws {
        sut = MovieFetcher(
            apollo: TestAPI(true),
            atlantis: TestAPI(true),
            cinamon: TestAPI(true),
            forum: TestAPI(true),
            multikino: TestAPI(false)
        )

        XCTAssertThrowsError(try sut.fetch(on: app.db).wait())
    }

    // MARK: Test Helpers

    private struct TestAPI: MovieAPI {
        enum TestError: Error {
            case error
        }

        let isSuccess: Bool

        init(_ isSuccess: Bool) {
            self.isSuccess = isSuccess
        }

        func fetchMovies(on db: Database) -> EventLoopFuture<Void> {
            isSuccess ? db.eventLoop.makeSucceededFuture(()) : db.eventLoop.makeFailedFuture(TestError.error)
        }
    }
}
