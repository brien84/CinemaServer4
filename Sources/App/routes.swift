import Fluent
import Vapor

func routes(_ app: Application) throws {

    app.get("all_") { req -> EventLoopFuture<[Movie]> in
        Movie.query(on: req.db).with(\.$showings).all()
    }

    app.get("vilnius_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(in: .vilnius, on: req)
    }

    app.get("kaunas_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(in: .kaunas, on: req)
    }

    app.get("klaipeda_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(in: .klaipeda, on: req)
    }

    app.get("siauliai_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(in: .siauliai, on: req)
    }

    app.get("panevezys_") { req -> EventLoopFuture<[Movie]> in
        queryMovies(in: .panevezys, on: req)
    }

    app.get("all") { req -> EventLoopFuture<[Movie]> in
        queryAllLegacyMovies(on: req)
    }

    app.get("vilnius") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(in: .vilnius, on: req)
    }

    app.get("kaunas") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(in: .kaunas, on: req)
    }

    app.get("klaipeda") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(in: .klaipeda, on: req)
    }

    app.get("siauliai") { req -> EventLoopFuture<[Movie]> in
        queryLegacyMovies(in: .siauliai, on: req)
    }

    app.get("posters", ":fileName") { req -> Response in
        let fileName = req.parameters.get("fileName")
        let path = "\(DirectoryConfiguration.detect().publicDirectory)Posters/" + (fileName ?? "")
        return req.fileio.streamFile(at: path)
    }

    app.get("update") { req -> EventLoopFuture<String> in
        req.eventLoop.makeSucceededFuture(Config.minimumSupportedClientVersion)
    }

    func queryMovies(in city: City, on req: Request) -> EventLoopFuture<[Movie]> {
        Movie.query(on: req.db).with(\.$showings).all().map { movies -> [Movie] in
            movies.forEach { movie in
                movie.$showings.value = movie.$showings.value?.filter({ $0.city == city })
            }

            return movies.filter { $0.showings.count > 0 }
        }
    }

    /// This function ignores `Showing`s which contain `Apollo` venue.
    ///
    /// This function is used in legacy apps and eventually will be removed in future release.
    func queryAllLegacyMovies(on req: Request) -> EventLoopFuture<[Movie]> {
        Movie.query(on: req.db).with(\.$showings).all().map { movies -> [Movie] in
            movies.forEach { movie in
                movie.$showings.value = movie.$showings.value?.filter({ $0.venue != "Apollo" })
            }

            return movies.filter { $0.showings.count > 0 }
        }
    }

    func queryLegacyMovies(in city: City, on req: Request) -> EventLoopFuture<[Movie]> {
        queryAllLegacyMovies(on: req).map { movies -> [Movie] in
            movies.forEach { movie in
                movie.$showings.value = movie.$showings.value?.filter({ $0.city == city })
            }

            return movies.filter { $0.showings.count > 0 }
        }
    }
}
