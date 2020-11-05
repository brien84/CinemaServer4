//
//  MainController.swift
//
//
//  Created by Marius on 2020-07-07.
//

import SendGrid
import Vapor

final class MainController {
    private var app: Application

    private let fetcher: MovieFetching
    private let organizer: MovieOrganization
    private let validator: MovieValidation
    private let sender: EmailSending

    init(app: Application, fetcher: MovieFetching, organizer: MovieOrganization, validator: MovieValidation, sender: EmailSending) {
        self.app = app
        self.fetcher = fetcher
        self.organizer = organizer
        self.validator = validator
        self.sender = sender
    }

    func update() -> EventLoopFuture<Void> {
        app.eventLoopGroup.next().scheduleTask(in: .hours(2)) {
            self.update()
        }

        app.logger.notice("\(Date()) - Starting update!")

        let transaction = app.db.transaction { db in
            Movie.query(on: db).with(\.$showings).delete().flatMap {
                self.fetcher.fetch(on: db).flatMap {
                    self.organizer.organize(on: db).flatMap {
                        self.validator.validate(on: db)
                    }
                }
            }
        }

        return transaction.flatMapAlways { result in
            switch result {
            case .success():
                self.app.logger.notice("\(Date()) - Successful update.")

                let report = self.validator.getReport()
                let email = self.createEmail(content: report)
                return self.sender.send(email: email)

            case .failure(let error):
                self.app.logger.notice("\(Date()) - Failed update: \(error)")

                let email = self.createEmail(content: "Failed update: \(error)")
                return self.sender.send(email: email)
            }
        }
    }

    private func createEmail(content: String) -> SendGridEmail {
        guard let emailAddress = Config.emailAddress else { fatalError("`Config.emailAddress` is nil!") }
        let address = EmailAddress(email: emailAddress)
        let personalizations = [Personalization(to: [address])]
        let content = [["type": "text/html", "value": content]]

        return SendGridEmail(personalizations: personalizations, from: address, subject: "Validation report", content: content)
    }
}
