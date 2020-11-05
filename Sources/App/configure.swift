import FluentSQLiteDriver
import SendGrid
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)

    // sendgrid setup
    Environment.process.SENDGRID_API_KEY = Config.sendGridKey
    app.sendgrid.initialize()

    databaseSetup(app)

    if app.environment != .testing {
        let controller = MainController(app: app,
                                        fetcher: app.movieFetcher,
                                        organizer: MovieOrganizer(),
                                        validator: MovieValidator(),
                                        sender: app.emailSender)

        _ = controller.update()
    }
}

private func databaseSetup(_ app: Application) {
    switch app.environment {
    case .testing:
        app.databases.use(.sqlite(.file("test.sqlite"), maxConnectionsPerEventLoop: 10), as: .sqlite)
    default:
        app.databases.use(.sqlite(.file("db.sqlite"), maxConnectionsPerEventLoop: 10), as: .sqlite)
    }

    app.migrations.add(CreateMovies())
    app.migrations.add(CreateShowings())
    app.migrations.add(CreateMovieProfiles())
    app.migrations.add(CreateTitleMappings())
}

struct Config {
    static let postersURL = URL(string: "http://localhost:8080/posters/")

    static let emailAddress: String? = nil
    static let sendGridKey: String? = nil
}
