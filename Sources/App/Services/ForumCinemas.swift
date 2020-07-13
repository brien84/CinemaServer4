//
//  ForumCinemas.swift
//  
//
//  Created by Marius on 2020-07-07.
//

import Vapor

struct ForumCinemas: MovieCustomization {
    private(set) var cinemaIdentifier: String? = "ForumCinemas"

    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func getMovies() -> EventLoopFuture<[Movie]> {
        getShowings().map { showings in
            let movies = self.createMovies(from: showings)
            
            return movies.map { self.customizeOriginalTitle(for: $0) }
        }
    }

    private func createMovies(from showings: [ForumShowing]) -> [Movie] {
        var movies = [Movie]()

        showings.forEach { showing in
            if let movie = movies.first(where: { $0.originalTitle == showing.originalTitle }) {
                guard let newShowing = Showing(from: showing) else { return }
                movie.showings.append(newShowing)
            } else {
                guard let newMovie = Movie(from: showing) else { return }
                movies.append(newMovie)
            }
        }

        return movies
    }

    // Returns array of `ForumShowing` from all areas.
    private func getShowings() -> EventLoopFuture<[ForumShowing]> {
        getAreas().flatMap { areas in
            areas.map { area in
                self.getShowings(in: area)
            }.flatten(on: self.client.eventLoop).map { $0.flatMap { $0 } }
        }
    }

    // Returns array of `ForumShowing` from specific area.
    private func getShowings(in area: Area) -> EventLoopFuture<[ForumShowing]> {
        client.get(makeShowingsURI(in: area)).map { res in
            do {
                let service = try JSONDecoder().decode(ShowingService.self, from: res.body ?? ByteBuffer())

                // Assigns `area` to each `ForumShowing` object.
                let showings = service.showings.map { showing -> ForumShowing in
                    var copy = showing
                    copy.area = area
                    return copy
                }

                return showings
            } catch {
                print("LOG: \(error)")
                return []
            }
        }
    }

    private func getAreas() -> EventLoopFuture<[Area]> {
        client.get(areasURI).map { res in
            do {
                let service = try JSONDecoder().decode(AreaService.self, from: res.body ?? ByteBuffer())
                return service.areas
            } catch {
                print("LOG: \(error)")
                return []
            }
        }
    }
}

extension ForumCinemas {
    private var areasURI: URI {
        URI(string: "http://m.forumcinemas.lt/xml/TheatreAreas/?format=json")
    }

    private func makeShowingsURI(in area: Area) -> URI {
        URI(string: "http://m.forumcinemas.lt/xml/Schedule/?format=json&nrOfDays=31&area=\(area.id)")
    }
}

extension Application {
    var forumCinemas: ForumCinemas {
        .init(client: self.client)
    }
}

extension Movie {
    fileprivate convenience init?(from showing: ForumShowing) {
        guard let newShowing = Showing(from: showing) else { return nil }

        let year = showing.year == nil ? nil : String(showing.year!)
        let duration = showing.duration == nil ? nil : String(showing.duration!) + " min"

        var ageRating = showing.ageRating

        // `N18` -> `N-18`
        if ageRating?.starts(with: "N") ?? false {
            ageRating!.insert("-", at: ageRating!.index(ageRating!.startIndex, offsetBy: 1))
        }

        // `Genre0, Genre1` -> `Genre0,Genre1` -> `[Genre0, Genre1]`
        let genres = showing.genres?.replacingOccurrences(of: ", ", with: ",").split(separator: ",").map { String($0) }

        self.init(title: showing.title,
                  originalTitle: showing.originalTitle,
                  year: year,
                  duration: duration,
                  ageRating: ageRating,
                  genres: genres,
                  showings: [newShowing])
    }
}

extension Showing {
    fileprivate convenience init?(from showing: ForumShowing) {
        guard let city = showing.area?.name else { return nil }
        guard let date = showing.date.convertToDate() else { return nil }

        self.init(city: city,
                  date: date,
                  venue: showing.venue,
                  is3D: false,
                  url: showing.url)
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
    let date: String
    let venue: String
    let url: String
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
