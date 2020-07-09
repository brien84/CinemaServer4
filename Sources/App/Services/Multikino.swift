//
//  Multikino.swift
//  
//
//  Created by Marius on 2020-07-09.
//

import Vapor

struct Multikino {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func getMovies() -> EventLoopFuture<[Movie]> {
        client.get("https://multikino.lt/data/filmswithshowings/1001").map { res in
            do {
                let multiService = try JSONDecoder().decode(MovieService.self, from: res.body ?? ByteBuffer())

                return multiService.movies.compactMap { movie in
                    Movie(from: movie)
                }
            } catch {
                print("LOG: \(error)")
                return []
            }
        }
    }
}

extension Application {
    var multikino: Multikino {
        .init(client: self.client)
    }
}

// MARK: - Decodable Helpers

extension Movie {
    fileprivate convenience init?(from movie: MultikinoMovie) {
        guard movie.showShowings == true else { return nil }

        let title = movie.title?.slice(from: nil, to: " (") ?? movie.title
        let originalTitle = movie.title?.slice(from: " (", to: ")") ?? movie.title

        let year: String? = {
            guard let yearSubstring = movie.year?.split(separator: ".").last else { return nil }
            return String(yearSubstring)
        }()

        let duration = movie.duration?.replacingOccurrences(of: ".", with: "")
        let genres = movie.genres?.names.map { $0.name }

        let showings = movie.showingServices.flatMap { service in
            service.showings.compactMap { showing in
                Showing(from: showing)
            }
        }

        self.init(title: title, originalTitle: originalTitle, year: year, duration: duration,
                  ageRating: movie.ageRating, genres: genres, plot: nil, poster: nil, showings: showings)
    }
}

extension Showing {
    fileprivate convenience init?(from showing: MultikinoShowing) {
        guard let date = showing.date.convertToDate() else { return nil }
        let is3D = showing.screen_type == "3D" ? true : false
        let url = "https://multikino.lt\(showing.link)"

        self.init(city: "Vilnius", date: date, venue: "Multikino", is3D: is3D, url: url)
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
    let showShowings: Bool
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
    let names: [Genre]

    struct Genre: Decodable {
        let name: String
    }
}

private struct ShowingService: Decodable {
    let showings: [MultikinoShowing]

    struct Time: Decodable {
        let screen_type: String
        let date: String
    }

    private enum CodingKeys: String, CodingKey {
        case showings = "times"
    }
}

private struct MultikinoShowing: Decodable {
    let screen_type: String
    let date: String
    let link: String
}
