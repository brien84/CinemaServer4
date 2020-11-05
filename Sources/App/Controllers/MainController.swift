//
//  MainController.swift
//  
//
//  Created by Marius on 2020-07-07.
//

import SendGrid
import Vapor

final class MainController: MovieCustomization {
    private var app: Application

    private let fetcher: MovieFetching
    private let sender: EmailSending

    private let logger = Logger(label: "MainController")

    var validationReport: String = ""

    init(app: Application, fetcher: MovieFetching, sender: EmailSending) {
        self.app = app
        self.fetcher = fetcher
        self.sender = sender
    }

    func update() -> EventLoopFuture<Void> {
        app.eventLoopGroup.next().scheduleTask(in: .hours(2)) {
            self.update()
        }

        logger.notice("\(Date()) - Update is starting!")

        let transaction = app.db.transaction { db in
            Movie.query(on: db).delete().flatMap {
                self.fetcher.fetch(on: db)
            }
        }

        return transaction.flatMapAlways { result in
            switch result {
            case .success():
                self.validationReport.append(contentsOf: "Update is successful!")
            case .failure(let error):
                self.validationReport = "Failed update: \(error)"
            }

            return self.sender.send(email: self.createEmail(content: self.validationReport))
        }
    }

    private func validate(_ movies: [Movie]) -> [Movie] {
        let merged = merge(movies)
        let profiled = merged.map { applyProfile(to: $0) }

        return profiled
    }

    private func merge(_ movies: [Movie]) -> [Movie] {
        var mergedMovies = [Movie]()

        movies.forEach { movie in
            if let existingMovie = mergedMovies.first(where: { $0 == movie }) {
                existingMovie.showings.append(contentsOf: movie.showings)
            } else {
                mergedMovies.append(movie)
            }
        }

        return mergedMovies
    }

    private func createEmail(content: String) -> SendGridEmail {
        guard let emailAddress = Config.emailAddress else { fatalError("`Config.emailAddress` is nil!") }
        let address = EmailAddress(email: emailAddress)
        let personalizations = [Personalization(to: [address])]
        let content = [["type": "text/html", "value": content]]

        return SendGridEmail(personalizations: personalizations, from: address, subject: "Validation report", content: content)
    }
}
