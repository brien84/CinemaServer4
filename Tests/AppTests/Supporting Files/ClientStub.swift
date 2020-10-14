//
//  ClientStub.swift
//  
//
//  Created by Marius on 2020-09-23.
//

import Vapor

/// Files are located in `Tests/AppTests/Supporting Files/TestData/`.
enum TestData: String {
    case cinamonBadData, cinamonValid
    case forumCinemasBadData, forumCinemasNoShowings, forumCinemasValid
    case noResponse
}

final class ClientStub: Client {
    var eventLoop: EventLoop
    var testData: TestData?

    init(eventLoop: EventLoop, testData: TestData?) {
        self.eventLoop = eventLoop
        self.testData = testData
    }

    func delegating(to eventLoop: EventLoop) -> Client {
        self.eventLoop = eventLoop
        return self
    }

    /// Returns `ClientResponse` with selected `TestData` in response body.
    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        let body = loadTestData()
        let response = ClientResponse(status: .ok, headers: ["Content-Type": "application/json"], body: body)

        return self.eventLoop.future(response)
    }

    private func loadTestData() -> ByteBuffer {
        guard let testData = testData else { return ByteBuffer() }

        let dir = DirectoryConfiguration.detect().workingDirectory
        let url = URL(fileURLWithPath: dir + "Tests/AppTests/Supporting Files/TestData/\(testData).json")
        let data = try? Data(contentsOf: url)

        return ByteBuffer(data: data ?? Data())
    }
}
