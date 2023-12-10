//
//  Atlantis.swift
//  
//
//  Created by Marius on 2022-12-07.
//

import Fluent
import Vapor

struct Atlantis: MovieAPI {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func fetchMovies(on db: Database) -> EventLoopFuture<Void> {
        client.get(.api).flatMap { res in
            do {
                let service = try JSONDecoder().decode(APIService.self, from: res.body ?? ByteBuffer())
                return createMovies(from: service, on: db)
            } catch {
                return client.eventLoop.makeFailedFuture(APIError(api: Atlantis.self, error: error))
            }
        }
    }

    private func createMovies(from service: APIService, on db: Database) -> EventLoopFuture<Void> {
        service.movies.map { serviceMovie in
            let movie = Movie(from: serviceMovie)
            let showings = serviceMovie.showings.compactMap { Showing(from: $0) }
            if showings.isEmpty { return db.eventLoop.makeSucceededVoidFuture() }

            return movie.create(on: db).flatMap {
                movie.$showings.create(showings, on: db)
            }
        }.flatten(on: db.eventLoop)
    }
}

extension Application {
    var atlantis: Atlantis {
        .init(client: self.client)
    }
}

// MARK: - Parsing Helpers

private extension Movie {
    convenience init(from movie: APIService.Movie) {
        self.init(
            title: movie.title,
            originalTitle: movie.originalTitle,
            year: nil,
            duration: String(movie.duration ?? 0) + " min",
            ageRating: nil,
            genres: movie.genres.compactMap{ $0.title }
        )
    }
}

private extension Showing {
    convenience init?(from showing: APIService.Movie.Showing) {
        guard let date = showing.date?.convertToDate() else { return nil }
        guard let uuid = showing.uuid else { return nil }

        self.init(
            city: .siauliai,
            date: date,
            venue: .atlantis,
            is3D: showing.screeningType == "3d",
            url: "https://www.atlantiscinemas.lt/kasa/seansas/\(uuid)"
        )
    }
}

private extension URI {
    static var api: URI {
        URI(string: "https://back.atlantiscinemas.lt/web/movies")
    }
}

private struct APIService: Decodable {
    let movies: [Movie]

    struct Movie: Decodable {
        let title: String?
        let originalTitle: String?
        let duration: Int?
        let genres: [Genre]
        let showings: [Showing]

        struct Genre: Decodable {
            let title: String?
        }

        private enum CodingKeys: String, CodingKey {
            case title = "title"
            case originalTitle = "origin_title"
            case duration = "runtime"
            case genres
            case showings = "sessions"
        }

        struct Showing: Decodable {
            let uuid: String?
            let date: String?
            let screeningType: String?

            private enum CodingKeys: String, CodingKey {
                case uuid
                case date = "starts_at"
                case screeningType = "screening_type"
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case movies = "data"
    }
}
