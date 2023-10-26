//
//  Atlantis.swift
//  
//
//  Created by Marius on 2022-12-07.
//

import Fluent
import Parsing
import Vapor

struct Atlantis: MovieAPI {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func fetchMovies(on db: Database) -> EventLoopFuture<Void> {
        client.get(.api).flatMap { res in
            do {
                let body = String(buffer: res.body ?? ByteBuffer())
                    .components(separatedBy: "\n").joined()
                    .components(separatedBy: "\t").joined()

                let showings = try APIParser.showings.parse(body)
                return createMovies(from: showings, on: db)
            } catch {
                return client.eventLoop.makeFailedFuture(APIError(api: Atlantis.self, error: error))
            }
        }
    }

    private func createMovies(from APIShowings: [APIParser.Showing], on db: Database) -> EventLoopFuture<Void> {
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
}

extension Application {
    var atlantis: Atlantis {
        .init(client: self.client)
    }
}

// MARK: - Parsing Helpers

private extension Movie {
    convenience init(from showing: APIParser.Showing) {
        self.init(
            title: String(showing.title),
            originalTitle: String(showing.originalTitle),
            year: nil,
            duration: nil,
            ageRating: AgeRating(rawValue: showing.ageRating),
            genres: showing.genres.split(separator: ",").map { String($0).trimSpaces() }
        )
    }
}

private extension Showing {
    convenience init?(from showing: APIParser.Showing) {
        guard let dateInterval = Double(showing.date) else { return nil }
        let dateWithoutTime = Date(timeIntervalSince1970: dateInterval)
        let calendar = Calendar.current.dateComponents([.year, .month, .day], from: dateWithoutTime)
        guard let year = calendar.year else { return nil }
        guard let month = calendar.month else { return nil }
        guard let day = calendar.day else { return nil }
        guard let date = "\(year)-\(month)-\(day) \(showing.time)".convertToDate() else { return nil }

        self.init(
            city: .siauliai,
            date: date,
            venue: .atlantis,
            is3D: showing.title.contains("3D") || showing.originalTitle.contains("3D"),
            url: "https://www.atlantiscinemas.lt/\(showing.url)"
        )
    }
}

private extension URI {
    static var api: URI {
        URI(string: "https://www.atlantiscinemas.lt/")
    }
}

private struct APIParser {
    struct Showing {
        let genres: String
        let ageRating: String
        let date: String
        let title: String
        let originalTitle: String
        let url: String
        let time: String
    }

    static let showings = Parse {
        Many {
            genres
            ageRating
            date
            title
            originalTitle
            url
            times
            Skip { PrefixUpTo("</li>") }
        } separator: {
            "</li>"
        } terminator: {
            "</li>"
        }
        Skip { Rest() }
    }.compactMap {
        $0.flatMap { output in
            let genres = output.0
            let ageRating = output.1
            let date = output.2
            let title = output.3
            let originalTitle = output.4
            let url = output.5
            let times = output.6

            return times.map { time in
                APIParser.Showing(
                    genres: genres,
                    ageRating: ageRating,
                    date: date,
                    title: title,
                    originalTitle: originalTitle,
                    url: url,
                    time: time
                )
            }
        }
    }

    private static let genres = Parse {
        Skip { PrefixThrough("class=\"genre\">") }
        PrefixUpTo("</div><div ")
    }.map(String.init)

    private static let ageRating = Parse {
        Skip { PrefixThrough("class=\"age-class\">") }
        PrefixUpTo("</div><div ")
    }.map(String.init)

    private static let date = Parse {
        Skip { PrefixThrough("sdate=") }
        PrefixUpTo("\"")
    }.map(String.init)

    private static let title = Parse {
        Skip { PrefixThrough("><h3>") }
        PrefixUpTo("<small>")
    }.map(String.init)

    private static let originalTitle = Parse {
        Skip { PrefixThrough("<small>") }
        PrefixUpTo("</small>")
    }.map(String.init)

    private static let url = Parse {
        Skip { PrefixThrough("href=\"/") }
        PrefixUpTo("\">Pirkti bilietą</a>")
    }.map(String.init)

    private static let times = Parse {
        Many {
            Parse {
                Skip { PrefixThrough("<time>") }
                PrefixUpTo("</time>")
            }.map(String.init)
        } separator: {
            Parse {
                PrefixThrough("</div>")
                "<div class=\"session\">"
            }
        } terminator: {
            Parse {
                PrefixThrough("</div>")
                "<div class=\"clearfix\"></div>"
            }
        }
    }
}
