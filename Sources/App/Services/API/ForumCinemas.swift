//
//  ForumCinemas.swift
//
//
//  Created by Marius on 2020-07-07.
//

import Fluent
import Vapor

struct ForumCinemas: MovieAPI {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func fetchMovies(on db: Database) -> EventLoopFuture<Void> {
        fetchAPIShowings().flatMap { showings in
            createMovies(from: showings, on: db)
        }
    }

    private func createMovies(from APIShowings: [APIService.Showing], on db: Database) -> EventLoopFuture<Void> {
        var APIShowings = APIShowings

        if let APIShowing = APIShowings.first {
            let sameTitleShowings = APIShowings.filter { $0.title == APIShowing.title }
            APIShowings = APIShowings.filter { $0.title != APIShowing.title }

            let movie = Movie(from: APIShowing)
            let showings = sameTitleShowings.compactMap { Showing(from: $0) }

            return movie.create(on: db).flatMap {
                movie.$showings.create(showings, on: db).flatMap {
                    createMovies(from: APIShowings, on: db)
                }
            }
        } else {
            return db.eventLoop.makeSucceededVoidFuture()
        }
    }

    /// Returns array of `APIService.Showing` from all `APIService.Area`.
    private func fetchAPIShowings() -> EventLoopFuture<[APIService.Showing]> {
        fetchAreas().flatMap { areas in
            areas.map { area in
                fetchAPIShowings(in: area)
            }.flatten(on: client.eventLoop).map { $0.flatMap { $0 } }
        }
    }

    /// Returns array of `APIService.Showing` from specific `APIService.Area`.
    private func fetchAPIShowings(in area: AreaService.Area) -> EventLoopFuture<[APIService.Showing]> {
        client.get(area.url).flatMapThrowing { res in
            do {
                let service = try JSONDecoder().decode(APIService.self, from: res.body ?? ByteBuffer())

                // Assigns `APIService.Area` to each `APIService.Showing` object.
                let showings = service.showings.map { showing in
                    var copy = showing
                    copy.area = area
                    return copy
                }

                return showings
            } catch {
                throw APIError(api: ForumCinemas.self, error: error)
            }
        }
    }

    private func fetchAreas() -> EventLoopFuture<[AreaService.Area]> {
        client.get(.areas).flatMapThrowing { res in
            do {
                let service = try JSONDecoder().decode(AreaService.self, from: res.body ?? ByteBuffer())
                return service.areas
            } catch {
                throw APIError(api: ForumCinemas.self, error: error)
            }
        }
    }
}

extension Application {
    var forumCinemas: ForumCinemas {
        .init(client: self.client)
    }
}

// MARK: - Decodable Helpers

private extension Movie {
    convenience init(from showing: APIService.Showing) {
        let year: String? = {
            guard let year = showing.year else { return nil }
            return String(year)
        }()

        let duration: String? = {
            guard let duration = showing.duration else { return nil }
            return String(duration) + " min"
        }()

        // ` Genre0, Genre1 ` -> `[Genre0, Genre1]`
        let genres = showing.genres?.split(separator: ",").map { String($0).trimSpaces() }

        self.init(
            title: showing.title,
            originalTitle: showing.originalTitle,
            year: year,
            duration: duration,
            ageRating: AgeRating(rawValue: showing.ageRating),
            genres: genres
        )
    }
}

private extension Showing {
    convenience init?(from showing: APIService.Showing) {
        guard let city = showing.area?.city else { return nil }
        guard let date = showing.date?.convertToDate() else { return nil }
        guard let url = showing.url else { return nil }

        self.init(
            city: city,
            date: date,
            venue: .forum,
            is3D: showing.is3D == "3D",
            url: url.sanitizeHTTP()
        )
    }
}

private extension URI {
    static var areas: URI {
        URI(string: "http://m.forumcinemas.lt/xml/TheatreAreas/?format=json")
    }
}

private struct AreaService: Decodable {
    let areas: [AreaService.Area]

    private enum CodingKeys: String, CodingKey {
        case areas = "TheatreAreas"
    }

    struct Area: Decodable {
        let id: Int
        let name: String

        var city: City? {
            switch name {
            case "Vilnius":
                return .vilnius
            case "Kaunas":
                return .kaunas
            case "Klaipėda":
                return .klaipeda
            case "Šiauliai":
                return .siauliai
            default:
                return nil
            }
        }

        var url: URI {
            URI(string: "http://m.forumcinemas.lt/xml/Schedule/?format=json&nrOfDays=31&area=\(id)")
        }

        private enum CodingKeys: String, CodingKey {
            case id = "ID"
            case name = "Name"
        }
    }
}

private struct APIService: Decodable {
    let showings: [APIService.Showing]

    private enum CodingKeys: String, CodingKey {
        case showings = "Shows"
    }

    struct Showing: Decodable {
        var area: AreaService.Area?

        let ageRating: String?
        let date: String?
        let duration: Int?
        let genres: String?
        let is3D: String?
        let originalTitle: String?
        let title: String?
        let url: String?
        let venue: String?
        let year: Int?

        private enum CodingKeys: String, CodingKey {
            case ageRating = "RatingLabel"
            case date = "dttmShowStart"
            case duration = "LengthInMinutes"
            case genres = "Genres"
            case is3D = "PresentationMethod"
            case originalTitle = "OriginalTitle"
            case title = "Title"
            case url = "ShowURL"
            case venue = "Theatre"
            case year = "ProductionYear"
        }
    }
}
