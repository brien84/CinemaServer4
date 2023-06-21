//
//  EmailSender.swift
//  
//
//  Created by Marius on 2020-11-02.
//

import SendGrid
import Vapor

protocol EmailSending {
    func send(content: String, subject: String) -> EventLoopFuture<Void>
}

struct EmailSender: EmailSending {
    private let eventLoop: EventLoop
    private let sendgrid: SendGridClient

    init(eventLoop: EventLoop, sendgrid: SendGridClient) {
        self.eventLoop = eventLoop
        self.sendgrid = sendgrid
    }

    func send(content: String, subject: String = "") -> EventLoopFuture<Void> {
        do {
            let email = createEmail(content: content, subject: subject)
            return try sendgrid.send(email: email, on: eventLoop)
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    private func createEmail(content: String, subject: String) -> SendGridEmail {
        guard let emailAddress = Config.emailAddress else { fatalError("`Config.emailAddress` is nil!") }
        let address = EmailAddress(email: emailAddress)
        let personalizations = [Personalization(to: [address])]
        let content = [["type": "text/html", "value": content]]
        return SendGridEmail(
            personalizations: personalizations,
            from: address,
            subject: subject,
            content: content
        )
    }
}

extension Application {
    var emailSender: EmailSender {
        .init(eventLoop: self.eventLoopGroup.any(), sendgrid: self.sendgrid.client)
    }
}
