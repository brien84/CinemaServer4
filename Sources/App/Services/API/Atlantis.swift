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
                let showings = try parseShowings(from: body)
                return createMovies(from: showings, on: db)
            } catch {
                return client.eventLoop.makeFailedFuture(error)
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

    private func parseShowings(from string: String) throws -> [APIParser.Showing] {
        let string = string.components(separatedBy: "\n").joined().components(separatedBy: "\t").joined()

        let scheduleBlocks = try APIParser.scheduleBlocks.parse(string)

        let schedules = scheduleBlocks.compactMap { block in
            do {
                return try APIParser.schedule.parse(block)
            } catch {
                return nil
            }
        }

        return try schedules.flatMap { schedule in
            try schedule.showingsData.flatMap { data in
                let showing = try APIParser.showing.parse(data)

                return showing.3.map { time in
                    APIParser.Showing(
                        title: String(showing.0),
                        originalTitle: String(showing.1),
                        url: String(showing.2),
                        time: String(time),
                        date: schedule.date
                    )
                }
            }
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
            title: showing.title,
            originalTitle: showing.originalTitle,
            year: nil,
            duration: nil,
            ageRating: nil,
            genres: nil
        )
    }
}

private extension Showing {
    convenience init?(from showing: APIParser.Showing) {
        guard let date = "\(showing.date) \(showing.time)".convertToDate()
        else { return nil }

        self.init(
            city: .siauliai,
            date: date,
            venue: "Atlantis",
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
    struct Schedule {
        let date: String
        let showingsData: [String]

        init(date: Substring, showingsData: [Substring]) {
            self.date = String(date)
            self.showingsData = showingsData.map { String($0) }
        }
    }

    struct Showing {
        let title: String
        let originalTitle: String
        let url: String
        let time: String
        let date: String
    }

    static let scheduleBlocks = Parse {
        Skip { PrefixThrough("<dl class=\"tabs\" id=\"movies\">") }
        Many {
            PrefixUpTo("</dd>")
        } separator: {
            "</dd>"
        } terminator: {
            "</dd>"
        }
        Skip { Rest() }
    }

    static let schedule = Parse(Schedule.init(date:showingsData:)) {
        Skip { PrefixThrough("<dt id=\"") }
        PrefixUpTo("\"><span>")
        Skip { PrefixThrough("movies_list\">") }
        Many {
            PrefixUpTo("</li>")
        } separator: {
            "</li>"
        } terminator: {
            "</li>"
        }
        Skip { Rest() }
    }

    static let showing = Parse {
        Self.title
        Self.originalTitle
        Self.url
        Self.times
        Skip { Rest() }
    }

    private static let title = Parse {
        Skip { PrefixThrough("><h3>") }
        PrefixUpTo("<small>")
    }

    private static let originalTitle = Parse {
        Skip { PrefixThrough("<small>") }
        PrefixUpTo("</small>")
    }

    private static let url = Parse {
        Skip { PrefixThrough("href=\"/") }
        PrefixUpTo("\">Pirkti bilietą</a>")
    }

    private static let times = Parse {
        Skip { PrefixThrough("class=\"sessions\"") }
        Many {
            Skip { PrefixThrough("<time>") }
            PrefixUpTo("</time>")
        } separator: {
            "</time>"
        } terminator: {
            "</time>"
        }
    }
}
