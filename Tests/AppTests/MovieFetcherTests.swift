//
//  MovieFetcherTests.swift
//
//
//  Created by Marius on 2020-09-26.
//

@testable import App
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
        sut = MovieFetcher(cinamon: makeCinamon(true), forum: makeForum(true), multikino: makeMultikino(true))

        try sut.fetch().wait()
    }

    func testFetchingThrowsWhenCinamonFails() throws {
        sut = MovieFetcher(cinamon: makeCinamon(false), forum: makeForum(true), multikino: makeMultikino(true))

        XCTAssertThrowsError(try sut.fetch().wait())
    }

    func testFetchingThrowsWhenForumFails() throws {
        sut = MovieFetcher(cinamon: makeCinamon(true), forum: makeForum(false), multikino: makeMultikino(true))

        XCTAssertThrowsError(try sut.fetch().wait())
    }

    func testFetchingThrowsWhenMultikinoFails() throws {
        sut = MovieFetcher(cinamon: makeCinamon(true), forum: makeForum(true), multikino: makeMultikino(false))

        XCTAssertThrowsError(try sut.fetch().wait())
    }
}

extension MovieFetcherTests {
    private func makeCinamon(_ isFetchingSuccessful: Bool) -> Cinamon {
        let data: TestData = isFetchingSuccessful ? .cinamonValid : .noResponse
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: data)

        return Cinamon(client: client, database: app.db)
    }

    private func makeForum(_ isFetchingSuccessful: Bool) -> ForumCinemas {
        let data: TestData = isFetchingSuccessful ? .forumCinemasValid : .noResponse
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: data)

        return ForumCinemas(client: client, database: app.db)
    }

    private func makeMultikino(_ isFetchingSuccessful: Bool) -> Multikino {
        let data: TestData = isFetchingSuccessful ? .multikinoValid : .noResponse
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), testData: data)

        return Multikino(client: client, database: app.db)
    }
}
