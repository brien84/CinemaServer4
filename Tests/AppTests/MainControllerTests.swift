//
//  MainControllerTests.swift
//
//
//  Created by Marius on 2020-10-04.
//

@testable import App
import Fluent
import SendGrid
import XCTVapor

final class MainControllerTests: XCTestCase {
    var app: Application!
    var sut: MainController!
    var fetcher: TestFetcher!
    var organizer: TestOrganizer!
    var validator: TestValidator!
    var sender: TestSender!

    override func setUp() {
        app = try! Application.testable()
        fetcher = TestFetcher()
        organizer = TestOrganizer()
        validator = TestValidator()
        sender = TestSender(eventLoop: app.eventLoopGroup.any())
        sut = MainController(
            app: app,
            fetcher: fetcher,
            organizer: organizer,
            validator: validator,
            sender: sender
        )
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testSuccessfulUpdate() throws {
        try sut.update().wait()

        XCTAssertEqual(sender.sentContent, validator.getReport())
    }

    func testDatabaseIsOverwrittenWhenUpdateIsSuccessful() throws {
        Movie.create(on: app.db)

        let initialCount = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(initialCount, 1)

        try sut.update().wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testFailedUpdateWhenFetchingFails() throws {
        fetcher.isSuccess = false

        try sut.update().wait()

        XCTAssertEqual(sender.sentContent, "Failed update: \(TestError.error)")
    }

    func testFailedUpdateWhenOrganizingFails() throws {
        organizer.isSuccess = false

        try sut.update().wait()

        XCTAssertEqual(sender.sentContent, "Failed update: \(TestError.error)")
    }

    func testFailedUpdateWhenValidationFails() throws {
        validator.isSuccess = false

        try sut.update().wait()

        XCTAssertEqual(sender.sentContent, "Failed update: \(TestError.error)")
    }

    func testDatabaseTrasactionIsCancelledWhenUpdateFails() throws {
        Movie.create(on: app.db)

        let initialCount = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(initialCount, 1)

        fetcher.isSuccess = false

        try sut.update().wait()

        let count = try Movie.query(on: app.db).count().wait()
        XCTAssertEqual(count, 1)
    }

    // MARK: Test Helpers

    enum TestError: Error {
        case error
    }

    class TestFetcher: MovieFetching {
        var isSuccess = true

        func fetch(on db: Database) -> EventLoopFuture<Void> {
            isSuccess ? db.eventLoop.makeSucceededFuture(()) : db.eventLoop.makeFailedFuture(TestError.error)
        }
    }

    class TestOrganizer: MovieOrganization {
        var isSuccess = true

        func organize(on db: Database) -> EventLoopFuture<Void> {
            isSuccess ? db.eventLoop.makeSucceededFuture(()) : db.eventLoop.makeFailedFuture(TestError.error)
        }
    }

    class TestValidator: MovieValidation {
        var isSuccess = true

        func getReport() -> String {
            "successful report!"
        }

        func validate(on db: Database) -> EventLoopFuture<Void> {
            isSuccess ? db.eventLoop.makeSucceededFuture(()) : db.eventLoop.makeFailedFuture(TestError.error)
        }
    }

    class TestSender: EmailSending {
        var eventLoop: EventLoop
        var sentContent: String?

        init(eventLoop: EventLoop) {
            self.eventLoop = eventLoop
        }

        func send(content: String, subject: String = "") -> EventLoopFuture<Void> {
            sentContent = content
            return eventLoop.makeSucceededFuture(())
        }
    }
}
