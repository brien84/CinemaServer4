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
        app = Application()
        let client = ClientStub(eventLoop: app.eventLoopGroup.next())
        sut = Cinamon(client: client)
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testGetMovies() {
        let movies = try? sut.getMovies().wait()

    }
}

final class ClientStub: Client {

    var eventLoop: EventLoop

    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }

    func delegating(to eventLoop: EventLoop) -> Client {
        self.eventLoop = eventLoop
        return self
    }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        let response = ClientResponse(status: .ok)

        return self.eventLoop.future(response)
    }
}
