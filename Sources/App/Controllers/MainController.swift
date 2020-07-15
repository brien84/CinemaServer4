//
//  MainController.swift
//  
//
//  Created by Marius on 2020-07-07.
//

import SendGrid
import Vapor

final class MainController: MovieCustomization, MovieValidation {
    private var app: Application

    private var forum: ForumCinemas
    private var multikino: Multikino
    private var cinamon: Cinamon
    private var sendgrid: SendGridClient

    var validationReport: String = ""

    init(app: Application) {
        self.app = app
        self.forum = app.forumCinemas
        self.multikino = app.multikino
        self.cinamon = app.cinamon
        self.sendgrid = app.sendgrid.client
    }

    func start() {
        update()
    }

    private func update() {
        let transaction = app.db.transaction { db in
            Movie.query(on: db).delete().flatMap {
                self.getMovies().flatMap { movies in
                    movies.map { $0.save(on: db) }.flatten(on: db.eventLoop)
                }
            }
        }

        transaction.whenComplete { result in
            switch result {
            case .success():
                self.validationReport.append(contentsOf: "Successful update!")
            case .failure(let error):
                self.validationReport = "Failed update: \(error)"
            }

            self.sendReport()
        }
    }

    private func getMovies() -> EventLoopFuture<[Movie]> {
        forum.getMovies().flatMap { forumMovies in
            self.multikino.getMovies().flatMap { multiMovies in
                self.cinamon.getMovies().map { cinamonMovies -> [Movie] in
                    var movies = [Movie]()

                    movies.append(contentsOf: forumMovies)
                    movies.append(contentsOf: multiMovies)
                    movies.append(contentsOf: cinamonMovies)

                    return self.validate(movies)
                }
            }
        }
    }

    private func validate(_ movies: [Movie]) -> [Movie] {
        let merged = merge(movies)
        let profiled = merged.map { applyProfile(to: $0) }

        return profiled.compactMap { validate($0) }
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
        print(validationReport)

        guard let email = generateEmail() else { print("Couldn't generate email!"); return }

        do {
            _ = try sendgrid.send(email: email, on: app.client.eventLoop)
        } catch {
            print(error)
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
