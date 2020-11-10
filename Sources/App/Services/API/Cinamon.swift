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
        client.get(apiURI).flatMap { res in
            do {
                let service = try JSONDecoder().decode(CinamonService.self, from: res.body ?? ByteBuffer())
                return self.createMovies(from: service, on: db)
            } catch {
                return self.client.eventLoop.makeFailedFuture(error)
            }
        }
    }

    private func createMovies(from service: CinamonService, on db: Database) -> EventLoopFuture<Void> {
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

extension Cinamon {
    private var apiURI: URI {
        URI(string: "https://cinamonkino.com/api/page/movies?cinema_id=77139293&timezone=Europe%2FTallinn&locale=lt")
    }
}

extension Application {
    var cinamon: Cinamon {
        .init(client: self.client)
    }
}

// MARK: - Decodable Helpers

extension Movie {
    fileprivate convenience init(from cinamonMovie: CinamonMovie) {
        // `2020-01-01` -> `2020`
        let year: String? = {
            guard let substring = cinamonMovie.year?.split(separator: "-").first else { return nil }
            return String(substring)
        }()

        // `69` -> `69 min`
        let duration: String? = {
            guard let movieDuration = cinamonMovie.duration else { return nil }
            return String(movieDuration) + " min"
        }()

        let genres: [String]? = {
            guard let genre = cinamonMovie.genre?.name else { return nil }
            return [genre]
        }()

        self.init(title: cinamonMovie.title,
                  originalTitle: cinamonMovie.originalTitle,
                  year: year,
                  duration: duration,
                  ageRating: cinamonMovie.ageRating,
                  genres: genres)
    }
}

extension Showing {
    fileprivate convenience init?(from cinamonShowing: CinamonShowing) {
        guard let date = cinamonShowing.showtime?.convertToDate() else { return nil }
        guard let is3D = cinamonShowing.is3D else { return nil }
        guard let pid = cinamonShowing.pid else { return nil }

        self.init(city: City.kaunas,
                  date: date,
                  venue: "Cinamon",
                  is3D: is3D,
                  url: "https://cinamonkino.com/mega/seat-plan/\(pid)/lt")
    }
}

private struct CinamonService: Decodable {
    let movies: [CinamonMovie]

    // `screens` contain local theater IDs, which we use to filter out local showings,
    // since API returns showings from theaters across multiple countries.
    let screens: [String]
}

private struct CinamonMovie: Decodable {
    let title: String?
    let originalTitle: String?
    let year: String?
    let duration: Int?
    let ageRating: String?
    let genre: Genre?
    let showings: [CinamonShowing]

    struct Genre: Decodable {
        let name: String
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
}

private struct CinamonShowing: Decodable {
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
