import Fluent
import Vapor

struct Route {
    enum Movie: CaseIterable {
        case all
        case vilnius
        case kaunas
        case klaipeda
        case siauliai
        case panevezys

        var path: PathComponent {
            switch self {
            case .all:
                return PathComponent.constant("all")
            case .vilnius:
                return PathComponent.constant("vilnius")
            case .kaunas:
                return PathComponent.constant("kaunas")
            case .klaipeda:
                return PathComponent.constant("klaipeda")
            case .siauliai:
                return PathComponent.constant("siauliai")
            case .panevezys:
                return PathComponent.constant("panevezys")
            }
        }
    }

    static let posters = PathComponent.constant("posters")
}

enum SupportedVersion: String {
    case v1_3 = "1.3"

    static let error = Abort(.custom(code: 469, reasonPhrase: "Version is not supported!"))
}

func routes(_ app: Application) throws {
    
    app.get(Route.posters, ":fileName") { req -> Response in
        let fileName = req.parameters.get("fileName")
        let path = "\(DirectoryConfiguration.detect().publicDirectory)Posters/" + (fileName ?? "")
        return req.fileio.streamFile(at: path)
    }

    func getVersion(from req: Request) throws -> SupportedVersion {
        guard
            let param = req.parameters.get("version"),
            let version = SupportedVersion(rawValue: param)
        else {
            throw SupportedVersion.error
        }

        return version
    }

    app.get(Route.Movie.all.path, ":version") { req in
        let version = try getVersion(from: req)

        switch version {
        case .v1_3:
            return queryMovies(
                in: [.vilnius, .kaunas, .klaipeda, .siauliai, .panevezys],
                at: [.apollo, .atlantis, .cinamon, .forum, .multikino],
                on: req
            )
        }
    }

    app.get(Route.Movie.vilnius.path, ":version") { req in
        let version = try getVersion(from: req)

        switch version {
        case .v1_3:
            return queryMovies(
                in: [.vilnius],
                at: [.apollo, .forum, .multikino],
                on: req
            )
        }
    }

    app.get(Route.Movie.kaunas.path, ":version") { req in
        let version = try getVersion(from: req)

        switch version {
        case .v1_3:
            return queryMovies(
                in: [.kaunas],
                at: [.cinamon, .forum],
                on: req
            )
        }
    }

    app.get(Route.Movie.klaipeda.path, ":version") { req in
        let version = try getVersion(from: req)

        switch version {
        case .v1_3:
            return queryMovies(
                in: [.klaipeda],
                at: [.forum],
                on: req
            )
        }
    }

    app.get(Route.Movie.siauliai.path, ":version") { req in
        let version = try getVersion(from: req)

        switch version {
        case .v1_3:
            return queryMovies(
                in: [.siauliai],
                at: [.atlantis, .forum],
                on: req
            )
        }
    }

    app.get(Route.Movie.panevezys.path, ":version") { req in
        let version = try getVersion(from: req)

        switch version {
        case .v1_3:
            return queryMovies(
                in: [.panevezys],
                at: [.apollo],
                on: req
            )
        }
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
