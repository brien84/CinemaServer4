//
//  Apollo.swift
//
//
//  Created by Marius on 2022-11-16.
//

import Fluent
import Vapor

struct Apollo: MovieAPI {
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
        APIService.Area.allCases.compactMap { area in
            fetchAPIShowings(in: area)
        }.flatten(on: client.eventLoop).map { $0.flatMap { $0 } }
    }

    /// Returns array of `APIService.Showing` from specific `APIService.Area`.
    private func fetchAPIShowings(in area: APIService.Area) -> EventLoopFuture<[APIService.Showing]> {
        client.get(area.url).flatMapThrowing { res in
            let service = try JSONDecoder().decode(APIService.self, from: res.body ?? ByteBuffer())

            let showings = service.showings.map {
                var copy = $0
                copy.area = area
                return copy
            }

            return showings
        }
    }
}

extension Application {
    var apollo: Apollo {
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

        let ageRating: String? = {
            guard var ageRating = showing.ageRating else { return nil }

            // `N18` -> `N-18`
            if ageRating.starts(with: "N") {
                ageRating.insert("-", at: ageRating.index(ageRating.startIndex, offsetBy: 1))
            }

            return ageRating
        }()

        // ` genre0, genre1 ` -> `[Genre0, Genre1]`
        let genres = showing.genres?.split(separator: ",").map { String($0).trimSpaces().firstCapitalized }

        self.init(
            title: showing.title,
            originalTitle: showing.originalTitle,
            year: year,
            duration: duration,
            ageRating: ageRating,
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
            venue: "Apollo",
            is3D: showing.is3D == "3D",
            url: url.sanitizeHTTP()
        )
    }
}

private struct APIService: Decodable {
    let showings: [APIService.Showing]

    private enum CodingKeys: String, CodingKey {
        case showings = "Shows"
    }

    struct Showing: Decodable {
        var area: Area?

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

    enum Area: Int, CaseIterable {
        case panevezys = 1018
        case vilnius = 1019

        var city: City {
            switch self {
            case .vilnius:
                return .vilnius
            case .panevezys:
                return .panevezys
            }
        }

        var url: URI {
            switch self {
            case .panevezys:
                return URI("https://www.apollokinas.lt/xml/Schedule/?format=json&nrOfDays=31&area=\(Self.panevezys.rawValue)")
            case .vilnius:
                return URI("https://www.apollokinas.lt/xml/Schedule/?format=json&nrOfDays=31&area=\(Self.vilnius.rawValue)")
            }
        }
    }
}
