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
        fetchAPIShowings().flatMap { showings in
            createMovies(from: showings, on: db)
        }
    }

    private func createMovies(from APIShowings: [APIShowing], on db: Database) -> EventLoopFuture<Void> {
        var APIShowings = APIShowings

        if let APIShowing = APIShowings.first {
            let sameTitleShowings = APIShowings.filter { $0.movie.title == APIShowing.movie.title }
            APIShowings = APIShowings.filter { $0.movie.title != APIShowing.movie.title }

            let movie = Movie(from: APIShowing)
            let showings = sameTitleShowings.compactMap { Showing(from: $0) }

            if showings.isEmpty {
                return createMovies(from: APIShowings, on: db)
            }

            return movie.create(on: db).flatMap {
                movie.$showings.create(showings, on: db).flatMap {
                    createMovies(from: APIShowings, on: db)
                }
            }
        } else {
            return db.eventLoop.makeSucceededVoidFuture()
        }
    }

    private func fetchAPIShowings() -> EventLoopFuture<[APIShowing]> {
        fetchURLService().flatMap { service in
            service.urls.map { url in
                client.get(url).flatMapThrowing { res in
                    do {
                        return try JSONDecoder().decode([APIShowing].self, from: res.body ?? ByteBuffer())
                    } catch {
                        throw APIError(api: Cinamon.self, error: error)
                    }
                }
            }.flatten(on: client.eventLoop).map { $0.flatMap { $0 } }
        }
    }

    private func fetchURLService() -> EventLoopFuture<URLService> {
        client.get(URLService.api).flatMapThrowing { res in
            do {
                return try JSONDecoder().decode(URLService.self, from: res.body ?? ByteBuffer())
            } catch {
                throw APIError(api: Cinamon.self, error: error)
            }
        }
    }
}

extension Application {
    var cinamon: Cinamon {
        .init(client: self.client)
    }
}

// MARK: - Decodable Helpers

private extension Movie {
    convenience init(from showing: APIShowing) {
        let movie = showing.movie

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
            ageRating: AgeRating(rawValue: movie.ageRating),
            genres: genres
        )
    }
}

private extension Showing {
    convenience init?(from showing: APIShowing) {
        guard showing.allowSales == 1 else { return nil }
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

private struct URLService: Decodable {
    static let api = URI(string: "https://cinamonkino.com/api/page/schedule?cinema_id=77139293&timezone=Europe%2FTallinn&locale=lt")
    private let dates: [String]

    var urls: [URI] {
        dates.map {
            "https://cinamonkino.com/api/schedule?cinema_id=77139293&timezone=Europe%2FTallinn&locale=lt&date=\($0)&include=film.genre,relatedAttributes"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case dates = "calendar_dates"
    }
}

private struct APIShowing: Decodable {
    let pid: Int?
    let showtime: String?
    let allowSales: Int?
    let is3D: Bool?
    let movie: APIShowing.Movie

    private enum CodingKeys: String, CodingKey {
        case pid
        case showtime
        case allowSales = "allow_web_sales"
        case is3D = "is_3d"
        case movie = "film"
    }

    struct Movie: Decodable {
        let title: String?
        let originalTitle: String?
        let year: String?
        let duration: Int?
        let ageRating: String?
        let genre: Genre?

        private enum CodingKeys: String, CodingKey {
            case title = "name"
            case originalTitle = "original_name"
            case year = "premiere_date"
            case duration = "runtime"
            case ageRating = "rating"
            case genre
        }

        struct Genre: Decodable {
            let name: String?
        }
    }
}
