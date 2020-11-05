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
    private var sendgrid: SendGridClient

    private let logger = Logger(label: "MainController")

    var validationReport: String = ""

    init(app: Application, fetcher: MovieFetching) {
        self.app = app
        self.fetcher = fetcher
        self.sendgrid = app.sendgrid.client
    }

    func start() {
        app.eventLoopGroup.next().scheduleTask(in: .hours(2)) {
            self.start()
        }

        update()
    }

    private func update() {
        logger.notice("\(Date()) - Update is starting!")

        let transaction = app.db.transaction { db in
            Movie.query(on: db).delete().flatMap {
                self.fetcher.fetch(on: db)
            }
        }

        transaction.whenComplete { result in
            switch result {
            case .success():
                self.validationReport.append(contentsOf: "Update is successful!")
            case .failure(let error):
                self.validationReport = "Failed update: \(error)"
            }

            self.sendReport()
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

    private func sendReport() {
        defer { validationReport = "" }
        logger.warning("\n\(validationReport)")

        guard let email = generateEmail() else { logger.error("Could not generate email!"); return }

        do {
            _ = try sendgrid.send(email: email, on: app.client.eventLoop)
        } catch {
            logger.error("Could not send email: \(error)")
        }
    }

    private func generateEmail() -> SendGridEmail? {
        guard let emailAddress = Config.emailAddress else { fatalError("`emailAddress` is nil!") }
        let address = EmailAddress(email: emailAddress)
        let content = [["type": "text/plain", "value": validationReport]]
        let personalizations = [Personalization(to: [address])]

        return SendGridEmail(personalizations: personalizations, from: address, subject: "Validation report", content: content)
    }
}
