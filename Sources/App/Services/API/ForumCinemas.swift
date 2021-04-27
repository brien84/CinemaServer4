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
        getForumShowings().flatMap { forumShowings in
            self.createMovies(from: forumShowings, on: db)
        }
    }

    private func createMovies(from forumShowings: [ForumShowing], on db: Database) -> EventLoopFuture<Void> {
        var forumShowings = forumShowings

        if let forumShowing = forumShowings.first {
            let movieShowings = forumShowings.filter { $0.title == forumShowing.title }
            forumShowings = forumShowings.filter { $0.title != forumShowing.title}

            let movie = Movie(from: forumShowing)
            let showings = movieShowings.compactMap { Showing(from: $0) }

            return movie.create(on: db).flatMap {
                movie.$showings.create(showings, on: db).flatMap {
                    self.createMovies(from: forumShowings, on: db)
                }
            }
        } else {
            return db.eventLoop.future()
        }
    }

    /// Returns array of `ForumShowing` from all areas.
    private func getForumShowings() -> EventLoopFuture<[ForumShowing]> {
        getAreas().flatMap { areas in
            areas.map { area in
                self.getForumShowings(in: area)
            }.flatten(on: self.client.eventLoop).map { $0.flatMap { $0 } }
        }
    }

    /// Returns array of `ForumShowing` from specific area.
    private func getForumShowings(in area: Area) -> EventLoopFuture<[ForumShowing]> {
        client.get(makeShowingsURI(for: area)).flatMapThrowing { res in

            let service = try JSONDecoder().decode(ShowingService.self, from: res.body ?? ByteBuffer())

            // Assigns `area` to each `ForumShowing` object.
            let showings = service.showings.map { showing -> ForumShowing in
                var copy = showing
                copy.area = area
                return copy
            }

            return showings
        }
    }

    private func getAreas() -> EventLoopFuture<[Area]> {
        client.get(areasURI).flatMapThrowing { res in
            let service = try JSONDecoder().decode(AreaService.self, from: res.body ?? ByteBuffer())
            return service.areas
        }
    }
}

extension ForumCinemas {
    private var areasURI: URI {
        URI(string: "http://m.forumcinemas.lt/xml/TheatreAreas/?format=json")
    }

    private func makeShowingsURI(for area: Area) -> URI {
        URI(string: "http://m.forumcinemas.lt/xml/Schedule/?format=json&nrOfDays=31&area=\(area.id)")
    }
}

extension Application {
    var forumCinemas: ForumCinemas {
        .init(client: self.client)
    }
}

// MARK: - Decodable Helpers

extension Movie {
    fileprivate convenience init(from forumShowing: ForumShowing) {
        let year: String? = {
            guard let year = forumShowing.year else { return nil }
            return String(year)
        }()

        let duration: String? = {
            guard let duration = forumShowing.duration else { return nil }
            return String(duration) + " min"
        }()

        let ageRating: String? = {
            guard var ageRating = forumShowing.ageRating else { return nil }

            // `N18` -> `N-18`
            if ageRating.starts(with: "N") {
                ageRating.insert("-", at: ageRating.index(ageRating.startIndex, offsetBy: 1))
            }

            return ageRating
        }()

        // ` Genre0, Genre1 ` -> `[Genre0, Genre1]`
        let genres = forumShowing.genres?.split(separator: ",").map { String($0).trimSpaces() }

        self.init(title: forumShowing.title,
                  originalTitle: forumShowing.originalTitle,
                  year: year,
                  duration: duration,
                  ageRating: ageRating,
                  genres: genres)
    }
}

extension Showing {
    fileprivate convenience init?(from forumShowing: ForumShowing) {
        guard let area = forumShowing.area?.name,
              let city = City(rawValue: area) else { return nil }
        guard let date = forumShowing.date?.convertToDate() else { return nil }
        guard let venue = forumShowing.venue else { return nil }
        guard let url = forumShowing.url else { return nil }

        self.init(city: city,
                  date: date,
                  venue: venue.sanitizeVenue(),
                  is3D: false,
                  url: url.sanitizeHTTP())
    }
}

private struct ShowingService: Decodable {
    let showings: [ForumShowing]

    private enum CodingKeys: String, CodingKey {
         case showings = "Shows"
    }
}

private struct ForumShowing: Decodable {
    let title: String?
    let originalTitle: String?
    let year: Int?
    let ageRating: String?
    let duration: Int?
    let genres: String?
    let date: String?
    let venue: String?
    let url: String?
    var area: Area?

    private enum CodingKeys: String, CodingKey {
        case title = "Title"
        case originalTitle = "OriginalTitle"
        case year = "ProductionYear"
        case ageRating = "RatingLabel"
        case duration = "LengthInMinutes"
        case genres = "Genres"
        case date = "dttmShowStart"
        case venue = "Theatre"
        case url = "ShowURL"
    }
}

private struct AreaService: Decodable {
    let areas: [Area]

    private enum CodingKeys: String, CodingKey {
        case areas = "TheatreAreas"
    }
}

private struct Area: Decodable {
    let id: Int
    let name: String

    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "Name"
    }
}

extension String {
    fileprivate func sanitizeVenue() -> String {
        return self.replacingOccurrences(of: " (Vilniuje)", with: "")
                   .replacingOccurrences(of: " Kaune", with: "")
                   .replacingOccurrences(of: " Klaipėdoje", with: "")
                   .replacingOccurrences(of: " Šiauliuose", with: "")
    }

    fileprivate func sanitizeHTTP() -> String {
        return self.replacingOccurrences(of: "http://", with: "https://")
    }
}
