import Fluent
import FluentSQLiteDriver
import SendGrid
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // database setup
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.migrations.add(CreateMovies())
    app.migrations.add(CreateShowings())

    // sendgrid setup
    Environment.process.SENDGRID_API_KEY = Config.sendGridKey
    app.sendgrid.initialize()

    // register routes
    try routes(app)

    let controller = MainController(app: app)
    controller.start()
}

struct Config {
    static let postersURL = URL(string: "http://localhost:8080/posters/")

    static let emailAddress: String? = nil
    static let sendGridKey: String? = nil
}
