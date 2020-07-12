//
//  Cinamon.swift
//  
//
//  Created by Marius on 2020-07-09.
//

import Vapor

struct Cinamon: TitleCustomization {
    private(set) var cinemaIdentifier = "Cinamon"

    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func getMovies() -> EventLoopFuture<[Movie]> {
        client.get(apiURI).map { res in
            do {
                let service = try JSONDecoder().decode(CinamonService.self, from: res.body ?? ByteBuffer())

                let movies = service.movies.map { Movie(from: $0, on: service.screens) }

                return movies.map { self.customizeOriginalTitle(for: $0) }
            } catch {
                print("LOG: \(error)")
                return []
            }
        }
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

extension Movie {
    fileprivate convenience init(from movie: CinamonMovie, on screens: [String]) {
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

        let genres: [String]? = {
            guard let genre = movie.genre?.name else { return nil }
            return [genre]
        }()

        let showings = movie.showings.compactMap { showing -> Showing? in
            if screens.contains(showing.screen) {
                return Showing(from: showing)
            } else {
                return nil
            }
        }

        self.init(title: movie.title,
                  originalTitle: movie.originalTitle,
                  year: year,
                  duration: duration,
                  ageRating: movie.ageRating,
                  genres: genres,
                  showings: showings)
    }
}

extension Showing {
    fileprivate convenience init?(from showing: CinamonShowing) {
        guard let date = showing.showtime.convertToDate() else { return nil }

        self.init(city: "Kaunas",
                  date: date,
                  venue: "Cinamon",
                  is3D: showing.is3D,
                  url: "https://cinamonkino.com/mega/seat-plan/\(showing.pid)/lt")
    }
}

private struct CinamonService: Decodable {
    let movies: [CinamonMovie]

    // `Screens` contains local theater IDs, which are used to filter out local showings,
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
    let pid: Int
    let screen: String
    let showtime: String
    let is3D: Bool

    private enum CodingKeys: String, CodingKey {
        case pid
        case screen = "screen_name"
        case showtime
        case is3D = "is_3d"
    }
}
