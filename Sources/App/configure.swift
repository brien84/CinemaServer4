import Fluent
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // database setup
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.migrations.add(CreateMovies())
    app.migrations.add(CreateShowings())

    // register routes
    try routes(app)

    let controller = MainController(app: app)
    controller.start()
}

struct Config {
    static let postersURL = URL(string: "http://localhost:8080/posters/")
}
