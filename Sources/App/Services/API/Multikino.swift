//
//  Multikino.swift
//
//
//  Created by Marius on 2020-07-09.
//

import Fluent
import Vapor

struct Multikino: MovieAPI {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func fetchMovies(on db: Database) -> EventLoopFuture<Void> {
        client.get(apiURI).flatMap { res in
            do {
                let service = try JSONDecoder().decode(APIService.self, from: res.body ?? ByteBuffer())
                return createMovies(from: service, on: db)
            } catch {
                return client.eventLoop.makeFailedFuture(error)
            }
        }
    }

    private func createMovies(from service: APIService, on db: Database) -> EventLoopFuture<Void> {
        service.movies.compactMap { apiMovie -> EventLoopFuture<Void>? in
            guard let movie = Movie(from: apiMovie) else { return nil }

            let showings = apiMovie.showings.flatMap { showing in
                showing.times.compactMap { time in
                    Showing(from: time)
                }
            }

            return movie.create(on: db).flatMap {
                movie.$showings.create(showings, on: db)
            }
        }.flatten(on: db.eventLoop)
    }
}

extension Multikino {
    private var apiURI: URI {
        URI(string: "https://multikino.lt/data/filmswithshowings/1001")
    }
}

extension Application {
    var multikino: Multikino {
        .init(client: self.client)
    }
}

// MARK: - Decodable Helpers

extension Movie {
    fileprivate convenience init?(from movie: APIService.Movie) {
        guard movie.showShowings == true else { return nil }

        // `Title (Original Title)` -> `Title`
        let title = movie.title?.slice(from: nil, to: " (") ?? movie.title

        // `Title (Original Title)` -> `Original Title`
        let originalTitle = movie.title?.slice(from: " (", to: ")") ?? movie.title

        // `01.01.2020` -> `2020`
        let year: String? = {
            guard let yearSubstring = movie.year?.split(separator: ".").last else { return nil }
            return String(yearSubstring)
        }()

        // `69 min.` -> `69 min`
        let duration = movie.duration?.replacingOccurrences(of: ".", with: "")

        // `[Genre(name: " Genre0 ", Genre(name: "Genre1 "]` -> `["Genre0", "Genre1"]`
        let genres = movie.genres?.names?.compactMap { genre -> String? in
            guard let genre = genre.name else { return nil }
            return genre.trimSpaces()
        }

        self.init(
            title: title,
            originalTitle: originalTitle,
            year: year,
            duration: duration,
            ageRating: movie.ageRating,
            genres: genres
        )
    }
}

extension Showing {
    fileprivate convenience init?(from time: APIService.Movie.Showings.Time) {
        guard let date = time.date?.convertToDate() else { return nil }
        guard let url = time.url else { return nil }

        self.init(
            city: .vilnius,
            date: date,
            venue: "Multikino",
            is3D: time.screenType == "3D",
            url: "https://multikino.lt\(url)"
        )
    }
}

private struct APIService: Decodable {
    let movies: [APIService.Movie]

    private enum CodingKeys: String, CodingKey {
        case movies = "films"
    }

    struct Movie: Decodable {
        let title: String?
        let duration: String?
        let ageRating: String?
        let year: String?
        let genres: Movie.Genres?
        let showShowings: Bool?
        let showings: [Showings]

        private enum CodingKeys: String, CodingKey {
            case title
            case duration = "info_runningtime"
            case ageRating = "info_age"
            case year = "info_release"
            case genres
            case showShowings = "show_showings"
            case showings
        }

        struct Genres: Decodable {
            let names: [Genre]?

            struct Genre: Decodable {
                let name: String?
            }
        }

        struct Showings: Decodable {
            let times: [Time]

            struct Time: Decodable {
                let date: String?
                let url: String?
                let screenType: String?

                private enum CodingKeys: String, CodingKey {
                    case date
                    case url = "link"
                    case screenType = "screen_type"
                }
            }
        }
    }
}
