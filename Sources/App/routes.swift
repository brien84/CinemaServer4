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
            let cityParam = req.parameters.get("city"),
            let venueParams = req.parameters.get("venues")?.split(separator: ",").map({ String($0) })
        else {
            throw Abort(.badRequest)
        }

        guard let city = City(rawValue: cityParam) else { throw Abort(.badRequest) }
        let venues = try venueParams.map {
            guard let venue = Venue(rawValue: $0) else { throw Abort(.badRequest) }
            return venue
        }

        return queryMovies(
            in: [city],
            at: venues,
            on: req
        )
    }

    // MARK: v1.2 - Deprecated

    app.get("all_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(
            in: [.vilnius, .kaunas, .klaipeda, .siauliai, .panevezys],
            at: [.apollo, .cinamon, .forum, .multikino],
            on: req
        )
    }

    app.get("vilnius_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(
            in: [.vilnius],
            at: [.apollo, .forum, .multikino],
            on: req
        )
    }

    app.get("kaunas_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(
            in: [.kaunas],
            at: [.cinamon, .forum],
            on: req
        )
    }

    app.get("klaipeda_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(
            in: [.klaipeda],
            at: [.forum],
            on: req
        )
    }

    app.get("siauliai_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(
            in: [.siauliai],
            at: [.forum],
            on: req
        )
    }

    app.get("panevezys_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(
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
        queryMovies(
            in: [.vilnius, .kaunas, .klaipeda, .siauliai],
            at: [.cinamon, .forum, .multikino],
            on: req
        )
    }

    app.get("vilnius") { req -> EventLoopFuture<[Movie]> in
        queryMovies(
            in: [.vilnius],
            at: [.forum, .multikino],
            on: req
        )
    }

    app.get("kaunas") { req -> EventLoopFuture<[Movie]> in
        queryMovies(
            in: [.kaunas],
            at: [.cinamon, .forum],
            on: req
        )
    }

    app.get("klaipeda") { req -> EventLoopFuture<[Movie]> in
        queryMovies(
            in: [.klaipeda],
            at: [.forum],
            on: req
        )
    }

    app.get("siauliai") { req -> EventLoopFuture<[Movie]> in
        queryMovies(
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
}
