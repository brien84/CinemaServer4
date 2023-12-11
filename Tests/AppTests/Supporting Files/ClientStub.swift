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
    var dataForResponse: ((ClientRequest) -> Data?)?

    init(eventLoop: EventLoop, data: Data?) {
        self.eventLoop = eventLoop
        self.data = data
    }

    init(eventLoop: EventLoop, dataForResponse: @escaping (ClientRequest) -> Data) {
        self.eventLoop = eventLoop
        self.dataForResponse = dataForResponse
    }

    func delegating(to eventLoop: EventLoop) -> Client {
        self.eventLoop = eventLoop
        return self
    }

    func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> {
        if let dataForResponse {
            data = dataForResponse(request)
        }

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
