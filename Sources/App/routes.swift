import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get("all") { req -> EventLoopFuture<[Movie]> in
        Movie.query(on: req.db).with(\.$showings).all()
    }

    app.get("vilnius") { req -> EventLoopFuture<[Movie]> in
        queryMovies(in: .vilnius, on: req)
    }

    app.get("kaunas") { req -> EventLoopFuture<[Movie]> in
        queryMovies(in: .kaunas, on: req)
    }

    app.get("klaipeda") { req -> EventLoopFuture<[Movie]> in
        queryMovies(in: .klaipeda, on: req)
    }

    app.get("siauliai") { req -> EventLoopFuture<[Movie]> in
        queryMovies(in: .siauliai, on: req)
    }

    app.get("posters", ":fileName") { req -> Response in
        let fileName = req.parameters.get("fileName")
        let path = "\(DirectoryConfiguration.detect().publicDirectory)Posters/" + (fileName ?? "")
        return req.fileio.streamFile(at: path)
    }

    func queryMovies(in city: City, on req: Request) -> EventLoopFuture<[Movie]> {
        Movie.query(on: req.db).with(\.$showings).all().map { movies -> [Movie] in

            movies.forEach { movie in
                movie.$showings.value = movie.$showings.value?.filter({ $0.city == city })
            }

            return movies.filter { $0.showings.count > 0 }
        }
    }
}
