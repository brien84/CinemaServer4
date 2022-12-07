//
//  Cinamon.swift
//
//
//  Created by Marius on 2020-07-09.
//

import Fluent
import Vapor

struct Cinamon: MovieAPI {
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
                return client.eventLoop.makeFailedFuture(error)
            }
        }
    }

    private func createMovies(from service: APIService, on db: Database) -> EventLoopFuture<Void> {
        service.movies.map { serviceMovie in
            let movie = Movie(from: serviceMovie)

            let showings = serviceMovie.showings.compactMap { cinamonShowing -> Showing? in
                guard let screen = cinamonShowing.screen else { return nil }
                // If `service.screens` does not contain `cinamonShowing.screen`,
                // it means that the showing is not shown in our location, thus should be discarded.
                guard service.screens.contains(screen) else { return nil }
                return Showing(from: cinamonShowing)
            }

            return movie.create(on: db).flatMap {
                movie.$showings.create(showings, on: db)
            }
        }.flatten(on: db.eventLoop)
    }
}

extension Application {
    var cinamon: Cinamon {
        .init(client: self.client)
    }
}

// MARK: - Decodable Helpers

private extension Movie {
    convenience init(from movie: APIService.Movie) {
        // `2020-01-01` -> `2020`
        let year: String? = {
            guard let substring = movie.year?.split(separator: "-").first else { return nil }
            return String(substring)
        }()

        // `69` -> `69 min`
        let duration: String? = {
            guard let movieDuration = movie.duration else { return nil }
            return String(movieDuration) + " min"
        }()

        // ` Genre ` -> `["Genre"]`
        let genres: [String]? = {
            guard let genre = movie.genre?.name else { return nil }
            return [genre.trimSpaces()]
        }()

        self.init(
            title: movie.title,
            originalTitle: movie.originalTitle,
            year: year,
            duration: duration,
            ageRating: movie.ageRating,
            genres: genres
        )
    }
}

private extension Showing {
    convenience init?(from showing: APIService.Movie.Showing) {
        guard let date = showing.showtime?.convertToDate() else { return nil }
        guard let is3D = showing.is3D else { return nil }
        guard let pid = showing.pid else { return nil }

        self.init(
            city: .kaunas,
            date: date,
            venue: .cinamon,
            is3D: is3D,
            url: "https://cinamonkino.com/mega/seat-plan/\(pid)/lt"
        )
    }
}

private extension URI {
    static var api: URI {
        URI(string: "https://cinamonkino.com/api/page/movies?cinema_id=77139293&timezone=Europe%2FTallinn&locale=lt")
    }
}

private struct APIService: Decodable {
    let movies: [Movie]

    // `screens` contain local theater IDs, which we use to filter out local showings,
    // since API returns showings from theaters across multiple countries.
    let screens: [String]

    struct Movie: Decodable {
        let title: String?
        let originalTitle: String?
        let year: String?
        let duration: Int?
        let ageRating: String?
        let genre: Genre?
        let showings: [Showing]

        struct Genre: Decodable {
            let name: String?
        }

        private enum CodingKeys: String, CodingKey {
            case title = "name"
            case originalTitle = "original_name"
            case year = "premiere_date"
            case duration = "runtime"
            case ageRating = "rating"
            case genre
            case showings = "sessions"
        }

        struct Showing: Decodable {
            let pid: Int?
            let screen: String?
            let showtime: String?
            let is3D: Bool?

            private enum CodingKeys: String, CodingKey {
                case pid
                case screen = "screen_name"
                case showtime
                case is3D = "is_3d"
            }
        }
    }
}
