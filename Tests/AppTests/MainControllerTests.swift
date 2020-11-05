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
    var sender: TestSender!

    override func setUp() {
        app = try! Application.testable()
        fetcher = TestFetcher()
        organizer = TestOrganizer()
        sender = TestSender(eventLoop: app.eventLoopGroup.next())
        sut = MainController(app: app, fetcher: fetcher, organizer: organizer, sender: sender)
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testUpdateIsFailingIfFetchingFails() throws {
        fetcher.isSuccess = false

        try sut.update().wait()

        let content = sender.getSentEmailContent()
        XCTAssertEqual(content, "Failed update: \(TestError.error)")
    }

    func testDatabaseIsOverwrittenWhenUpdateIsSuccessful() throws {
        Movie.create(title: "", originalTitle: "TITLE", year: "", duration: "",
                     ageRating: "", genres: [], plot: "", poster: "", on: app.db)

        try sut.update().wait()

        let count = try Movie.query(on: self.app.db).count().wait()
        XCTAssertEqual(count, 0)
    }

    func testUpdateIsFailingIfOrganizingFails() throws {
        organizer.isSuccess = false

        try sut.update().wait()

        let content = sender.getSentEmailContent()
        XCTAssertEqual(content, "Failed update: \(TestError.error)")
    }

    func testDatabaseTrasactionIsCancelledIfUpdateFails() throws {
        Movie.create(title: "", originalTitle: "TITLE", year: "", duration: "",
                     ageRating: "", genres: [], plot: "", poster: "", on: app.db)
        fetcher.isSuccess = false

        try sut.update().wait()

        let count = try Movie.query(on: self.app.db).count().wait()
        XCTAssertEqual(count, 1)
    }

    func testEmailConfiguration() throws {
        try sut.update().wait()

        let email = sender.sentEmail

        XCTAssertEqual(email?.from?.email, Config.emailAddress)
        XCTAssertEqual(email?.personalizations?.first?.to?.first?.email, Config.emailAddress)
        XCTAssertEqual(email?.subject, "Validation report")
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

    class TestSender: EmailSending {
        var eventLoop: EventLoop
        var sentEmail: SendGridEmail?

        init(eventLoop: EventLoop) {
            self.eventLoop = eventLoop
        }

        func send(email: SendGridEmail) -> EventLoopFuture<Void> {
            sentEmail = email
            return eventLoop.makeSucceededFuture(())
        }

        func getSentEmailContent() -> String {
            guard let content = sentEmail?.content?.first?["value"]
                else { XCTFail("Could not get email content!"); return "" }

            return content
        }
    }
}
