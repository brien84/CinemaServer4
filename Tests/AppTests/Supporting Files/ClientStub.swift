//
//  ClientStub.swift
//  
//
//  Created by Marius on 2020-09-23.
//

import Vapor

final class ClientStub: Client {
    var eventLoop: EventLoop
    var data: Data?

    init(eventLoop: EventLoop, data: Data?) {
        self.eventLoop = eventLoop
        self.data = data
    }

    func delegating(to eventLoop: EventLoop) -> Client {
        self.eventLoop = eventLoop
        return self
    }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        let response: ClientResponse

        if let data = data {
            let body = ByteBuffer(data: data)
            response = ClientResponse(status: .ok, headers: ["Content-Type": "application/json"], body: body)
        } else {
            response = ClientResponse(status: .notFound, headers: ["Content-Type": "application/json"], body: ByteBuffer())
        }

        return self.eventLoop.future(response)
    }
}
