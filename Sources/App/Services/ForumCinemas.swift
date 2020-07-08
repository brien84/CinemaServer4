//
//  ForumCinemas.swift
//  
//
//  Created by Marius on 2020-07-07.
//

import Vapor

struct ForumCinemas {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func getMovies() -> EventLoopFuture<[Movie]> {
        getAllShowings().map { showings in
            self.createMovies(from: showings)
        }
    }

    private func createMovies(from showings: [ForumShowing]) -> [Movie] {
        var movies = [Movie]()

        showings.forEach { showing in
            if let movie = movies.first(where: { $0.originalTitle == showing.originalTitle }) {
                guard let newShowing = showing.convertToShowing() else { return }
                movie.showings.append(newShowing)
            } else {
                guard let newMovie = showing.convertToMovie() else { return }
                movies.append(newMovie)
            }
        }

        return movies
    }

    private func getAllShowings() -> EventLoopFuture<[ForumShowing]> {
        return getAreas().flatMap { areas in
            areas.map { area in
                self.getShowings(in: area)
            }.flatten(on: self.client.eventLoop).map { $0.flatMap { $0 } }
        }
    }

    private func getShowings(in area: Area) -> EventLoopFuture<[ForumShowing]> {
        let uri = URI(string: "http://m.forumcinemas.lt/xml/Schedule/?format=json&nrOfDays=31&area=\(area.id)")

        return client.get(uri).map { res in
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
        let uri = URI(string: "http://m.forumcinemas.lt/xml/TheatreAreas/?format=json")

        return client.get(uri).map { res in
            do {
                let service = try JSONDecoder().decode(AreaService.self, from: res.body ?? ByteBuffer())
                return service.areas
            } catch {
                print("LOG: \(error)")
                return []
            }
        }
    }

    // MARK: - Decodable Helpers

    private struct ForumShowing: Decodable {
        let title: String
        let originalTitle: String
        let year: Int
        let ageRating: String
        let duration: Int
        let genres: String
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

        func convertToShowing() -> Showing? {
            guard let city = self.area?.name else { return nil }
            guard let date = self.date.convertToDate() else { return nil }

            return Showing(city: city, date: date, venue: self.venue, is3D: false, url: self.url)
        }

        func convertToMovie() -> Movie? {
            guard let showing = self.convertToShowing() else { return nil }
            let genres = self.genres.split(separator: ",").map { String($0) }

            return Movie(title: self.title, originalTitle: self.originalTitle, year: String(self.year), duration: String(self.duration),
                         ageRating: self.ageRating, genres: genres, plot: nil, poster: nil, showings: [showing])
        }
    }

    private struct ShowingService: Decodable {
        let showings: [ForumShowing]

        private enum CodingKeys: String, CodingKey {
             case showings = "Shows"
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

    private struct AreaService: Decodable {
        let areas: [Area]

        private enum CodingKeys: String, CodingKey {
            case areas = "TheatreAreas"
        }
    }
}

extension Application {
    var forumCinemas: ForumCinemas {
        .init(client: self.client)
    }
}
