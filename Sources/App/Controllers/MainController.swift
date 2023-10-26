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
    private let validator: ContentValidation
    private let sender: EmailSending?

    init(
        app: Application,
        fetcher: MovieFetching,
        organizer: MovieOrganization,
        validator: ContentValidation,
        sender: EmailSending?
    ) {
        self.app = app
        self.fetcher = fetcher
        self.organizer = organizer
        self.validator = validator
        self.sender = sender
    }

    func update() -> EventLoopFuture<Void> {
        app.eventLoopGroup.any().scheduleTask(in: .hours(2)) {
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
                guard let sender = self.sender else { return transaction.eventLoop.makeSucceededVoidFuture() }
                let report = self.validator.getReport()
                return sender.send(content: report, subject: "Validation report")

            case .failure(let error):
                self.app.logger.notice("\(Date()) - Failed update: \(error)")
                guard let sender = self.sender else { return transaction.eventLoop.makeSucceededVoidFuture() }
                return sender.send(content: "Failed update: \(error)", subject: "Validation report")
            }
        }
    }
}
