import Fluent
import Vapor

enum SupportedVersion: String {
    case v1_3 = "1.3"

    static let error = Abort(.custom(code: 469, reasonPhrase: "Version is not supported!"))
}

func routes(_ app: Application) throws {
    app.get("images", "posters", ":fileName") { req -> Response in
        guard let fileName = req.parameters.get("fileName") else { return Response(status: .notFound) }
        let path = Paths.postersDirectory.appendingPathExtension(fileName)
        return req.fileio.streamFile(at: path.absoluteString)
    }

    app.get(":city", ":venues") { req in
        let city = try getCity(req.parameters)
        let venues = try getVenues(req.parameters)
        return queryMovies(in: [city], at: venues, on: req)
    }

    app.get("vilnius", ":venues") { req -> EventLoopFuture<[Movie]> in
        let venues = try getVenues(req.parameters)
        return queryMovies(in: [.vilnius], at: venues, on: req)
    }

    app.get("kaunas", ":venues") { req -> EventLoopFuture<[Movie]> in
        let venues = try getVenues(req.parameters)
        return queryMovies(in: [.kaunas], at: venues, on: req)
    }

    app.get("klaipeda", ":venues") { req -> EventLoopFuture<[Movie]> in
        let venues = try getVenues(req.parameters)
        return queryMovies(in: [.klaipeda], at: venues, on: req)
    }

    app.get("siauliai", ":venues") { req -> EventLoopFuture<[Movie]> in
        let venues = try getVenues(req.parameters)
        return queryMovies(in: [.siauliai], at: venues, on: req)
    }

    // MARK: v1.2 - Deprecated

    app.get("update") { req in
        "1.3"
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
        queryLegacyMovies(in: [.vilnius], at: [.forum, .multikino], on: req)
    }

    app.get("kaunas") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(in: [.kaunas], at: [.cinamon, .forum], on: req)
    }

    app.get("klaipeda") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(in: [.klaipeda], at: [.forum], on: req)
    }

    app.get("siauliai") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(in: [.siauliai], at: [.forum], on: req)
    }
}

private func getCity(_ parameters: Parameters) throws -> City {
    guard let string = parameters.get("city") else { throw Abort(.badRequest) }
    guard let city = City(rawValue: string) else { throw Abort(.badRequest) }
    return city
}

private func getVenues(_ parameters: Parameters) throws -> [Venue] {
    guard let string = parameters.get("venues") else { throw Abort(.badRequest) }
    let venues = string.split(separator: ",").compactMap { Venue(rawValue: String($0)) }
    guard !venues.isEmpty else { throw Abort(.badRequest) }
    return venues
}

private func queryMovies(in cities: [City], at venues: [Venue], on req: Request) -> EventLoopFuture<[Movie]> {
    Movie.query(on: req.db).with(\.$showings).with(\.$featured).all().mapEachCompact { movie in
        movie.$showings.value = movie.$showings.value?.filter({ cities.contains($0.city) && venues.contains($0.venue) })
        return movie.showings.count > .zero ? movie : nil
    }
}

private func queryLegacyMovies(in cities: [City], at venues: [Venue], on req: Request) -> EventLoopFuture<[Movie]> {
    queryMovies(in: cities, at: venues, on: req).mapEach { movie in
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

        return movie
    }
}
