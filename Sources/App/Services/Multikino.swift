//
//  Multikino.swift
//
//
//  Created by Marius on 2020-07-09.
//

import Fluent
import Vapor

struct Multikino {
    private let client: Client
    private let db: Database

    init(client: Client, database: Database) {
        self.client = client
        self.db = database
    }

    func getMovies() -> EventLoopFuture<Void> {
        client.get(apiURI).flatMap { res in
            do {
                let service = try JSONDecoder().decode(MovieService.self, from: res.body ?? ByteBuffer())
                return self.createMovies(from: service)
            } catch {
                return self.client.eventLoop.makeFailedFuture(error)
            }
        }
    }

    private func createMovies(from service: MovieService) -> EventLoopFuture<Void> {
        service.movies.compactMap { multikinoMovie -> EventLoopFuture<Void>? in
            guard let movie = Movie(from: multikinoMovie) else { return nil }

            let showings = multikinoMovie.showingServices.flatMap { service in
                service.showings.compactMap { multikinoShowing in
                    Showing(from: multikinoShowing)
                }
            }

            return movie.create(on: db).flatMap {
                movie.$showings.create(showings, on: self.db)
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
        .init(client: self.client, database: self.db)
    }
}

// MARK: - Decodable Helpers

extension Movie {
    fileprivate convenience init?(from movie: MultikinoMovie) {
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

        let genres = movie.genres?.names?.compactMap { $0.name }

        self.init(title: title,
                  originalTitle: originalTitle,
                  year: year,
                  duration: duration,
                  ageRating: movie.ageRating,
                  genres: genres)
    }
}

extension Showing {
    fileprivate convenience init?(from multikinoShowing: MultikinoShowing) {
        guard let date = multikinoShowing.date?.convertToDate() else { return nil }
        guard let url = multikinoShowing.url else { return nil }
        let is3D = multikinoShowing.screenType == "3D" ? true : false

        self.init(city: "Vilnius",
                  date: date,
                  venue: "Multikino",
                  is3D: is3D,
                  url: "https://multikino.lt\(url)")
    }
}

private struct MovieService: Decodable {
    let movies: [MultikinoMovie]

    private enum CodingKeys: String, CodingKey {
        case movies = "films"
    }
}

private struct MultikinoMovie: Decodable {
    let title: String?
    let duration: String?
    let ageRating: String?
    let year: String?
    let genres: Genres?
    let showShowings: Bool?
    let showingServices: [ShowingService]

    private enum CodingKeys: String, CodingKey {
        case title
        case duration = "info_runningtime"
        case ageRating = "info_age"
        case year = "info_release"
        case genres
        case showShowings = "show_showings"
        case showingServices = "showings"
    }
}

private struct Genres: Decodable {
    let names: [Genre]?

    struct Genre: Decodable {
        let name: String?
    }
}

private struct ShowingService: Decodable {
    let showings: [MultikinoShowing]

    private enum CodingKeys: String, CodingKey {
        case showings = "times"
    }
}

private struct MultikinoShowing: Decodable {
    let date: String?
    let url: String?
    let screenType: String?

    private enum CodingKeys: String, CodingKey {
        case date
        case url = "link"
        case screenType = "screen_type"
    }
}
