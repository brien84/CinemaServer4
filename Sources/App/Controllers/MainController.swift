//
//  MainController.swift
//  
//
//  Created by Marius on 2020-07-07.
//

import SendGrid
import Vapor

class MainController: MovieCustomization, MovieValidation {
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
        getMovies().whenSuccess { movies in
            let mergedMovies = self.merge(movies)
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

                    return movies
                }
            }
        }
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
        guard !validationReport.isEmpty else { return }

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
