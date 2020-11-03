//
//  EmailSender.swift
//  
//
//  Created by Marius on 2020-11-02.
//

import SendGrid
import Vapor

protocol EmailSending {
    func send(email: SendGridEmail) -> EventLoopFuture<Void>
}

struct EmailSender: EmailSending {
    private let eventLoop: EventLoop
    private let sendgrid: SendGridClient

    init(eventLoop: EventLoop, sendgrid: SendGridClient) {
        self.eventLoop = eventLoop
        self.sendgrid = sendgrid
    }

    func send(email: SendGridEmail) -> EventLoopFuture<Void> {
        do {
            return try sendgrid.send(email: email, on: eventLoop)
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension Application {
    var emailSender: EmailSending {
        .init(db: self.db)
    }
}
