import Fluent
import Vapor

enum SupportedVersion: String {
    case v1_3 = "1.3"

    static let error = Abort(.custom(code: 469, reasonPhrase: "Version is not supported!"))
}

func routes(_ app: Application) throws {

    app.get("posters", ":fileName") { req -> Response in
        let fileName = req.parameters.get("fileName")
        let path = "\(DirectoryConfiguration.detect().publicDirectory)Posters/" + (fileName ?? "")
        return req.fileio.streamFile(at: path)
    }

    app.get(":city", ":venues") { req in
        guard
            let cityParameter = req.parameters.get("city"),
            let city = City(rawValue: cityParameter)
        else {
            throw Abort(.badRequest)
        }

        guard let venueParameter = req.parameters.get("venues") else { throw Abort(.badRequest) }

        let venues = try venueParameter
            .split(separator: ",")
            .map { String($0) }
            .map {
                guard let venue = Venue(rawValue: $0) else { throw Abort(.badRequest) }
                return venue
            }

        return queryMovies(
            in: [city],
            at: venues,
            on: req
        )
    }

    app.get("vilnius", ":venues") { req -> EventLoopFuture<[Movie]> in
        guard let venueParameter = req.parameters.get("venues") else { throw Abort(.badRequest) }

        let venues = try venueParameter
            .split(separator: ",")
            .map { String($0) }
            .map {
                guard let venue = Venue(rawValue: $0) else { throw Abort(.badRequest) }
                return venue
            }

        return queryMovies(
            in: [.vilnius],
            at: venues,
            on: req
        )
    }

    app.get("kaunas", ":venues") { req -> EventLoopFuture<[Movie]> in
        guard let venueParameter = req.parameters.get("venues") else { throw Abort(.badRequest) }

        let venues = try venueParameter
            .split(separator: ",")
            .map { String($0) }
            .map {
                guard let venue = Venue(rawValue: $0) else { throw Abort(.badRequest) }
                return venue
            }

        return queryMovies(
            in: [.kaunas],
            at: venues,
            on: req
        )
    }

    app.get("klaipeda", ":venues") { req -> EventLoopFuture<[Movie]> in
        guard let venueParameter = req.parameters.get("venues") else { throw Abort(.badRequest) }

        let venues = try venueParameter
            .split(separator: ",")
            .map { String($0) }
            .map {
                guard let venue = Venue(rawValue: $0) else { throw Abort(.badRequest) }
                return venue
            }

        return queryMovies(
            in: [.klaipeda],
            at: venues,
            on: req
        )
    }

    app.get("siauliai", ":venues") { req -> EventLoopFuture<[Movie]> in
        guard let venueParameter = req.parameters.get("venues") else { throw Abort(.badRequest) }

        let venues = try venueParameter
            .split(separator: ",")
            .map { String($0) }
            .map {
                guard let venue = Venue(rawValue: $0) else { throw Abort(.badRequest) }
                return venue
            }

        return queryMovies(
            in: [.siauliai],
            at: venues,
            on: req
        )
    }

    // MARK: v1.2 - Deprecated

    app.get("all_") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.vilnius, .kaunas, .klaipeda, .siauliai, .panevezys],
            at: [.apollo, .cinamon, .forum, .multikino],
            on: req
        )
    }

    app.get("vilnius_") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.vilnius],
            at: [.apollo, .forum, .multikino],
            on: req
        )
    }

    app.get("kaunas_") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.kaunas],
            at: [.cinamon, .forum],
            on: req
        )
    }

    app.get("klaipeda_") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.klaipeda],
            at: [.forum],
            on: req
        )
    }

    app.get("siauliai_") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.siauliai],
            at: [.forum],
            on: req
        )
    }

    app.get("panevezys_") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.panevezys],
            at: [.apollo],
            on: req
        )
    }

    app.get("update") { req in
        "1.1.2"
    }

    // MARK: v1.1.2 - Deprecated

    app.get("all") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.vilnius, .kaunas, .klaipeda, .siauliai],
            at: [.cinamon, .forum, .multikino],
            on: req
        )
    }

    app.get("vilnius") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.vilnius],
            at: [.forum, .multikino],
            on: req
        )
    }

    app.get("kaunas") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.kaunas],
            at: [.cinamon, .forum],
            on: req
        )
    }

    app.get("klaipeda") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.klaipeda],
            at: [.forum],
            on: req
        )
    }

    app.get("siauliai") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(
            in: [.siauliai],
            at: [.forum],
            on: req
        )
    }

    func queryMovies(in cities: [City], at venues: [Venue], on req: Request) -> EventLoopFuture<[Movie]> {
        Movie.query(on: req.db).with(\.$showings).all().map { movies -> [Movie] in
            movies.forEach { movie in
                movie.$showings.value = movie.$showings.value?.filter({ cities.contains($0.city) && venues.contains($0.venue) })
            }

            return movies.filter { $0.showings.count > 0 }
        }
    }

    func queryLegacyMovies(in cities: [City], at venues: [Venue], on req: Request) -> EventLoopFuture<[Movie]> {
        Movie.query(on: req.db).with(\.$showings).all().map { movies -> [Movie] in
            movies.forEach { movie in
                movie.$showings.value = movie.$showings.value?.filter({ cities.contains($0.city) && venues.contains($0.venue) })
            }

            let movies = movies.filter { $0.showings.count > 0 }

            movies.forEach { movie in
                movie.showings.forEach { showing in
                    switch showing.city {
                    case .vilnius:
                        showing.city = .vilnius_
                    case .kaunas:
                        showing.city = .kaunas_
                    case .klaipeda:
                        showing.city = .klaipeda_
                    case .siauliai:
                        showing.city = .siauliai_
                    case .panevezys:
                        showing.city = .panevezys_
                    default:
                        return
                    }

                    switch showing.venue {
                    case .apollo:
                        showing.venue = .apollo_
                    case .cinamon:
                        showing.venue = .cinamon_
                    case .forum:
                        showing.venue = .forum_
                    case .multikino:
                        showing.venue = .multikino_
                    default:
                        return
                    }
                }
            }

            return movies
        }
    }
}
