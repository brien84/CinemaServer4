import Vapor

func routes(_ app: Application) throws {
    app.get("all") { req in
        Movie.query(on: req.db).all()
    }
}
