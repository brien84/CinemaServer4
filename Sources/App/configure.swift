import FluentSQLiteDriver
import SendGrid
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)

    // sendgrid configuration
    if let sendgridKey = Config.sendgridKey {
        Environment.process.SENDGRID_API_KEY = sendgridKey
        app.sendgrid.initialize()
    }

    // HTTPClient configuration
    app.http.client.configuration.httpVersion = .http1Only

    databaseConfiguration(app)

    if app.environment != .testing, !CommandLine.arguments.contains("migrate") {
        let controller = MainController(
                            app: app,
                            fetcher: app.movieFetcher,
                            organizer: MovieOrganizer(),
                            validator: MovieValidator(),
                            sender: Config.sendgridKey == nil ? nil : app.emailSender
                         )

        _ = controller.update()
    }
}

private func databaseConfiguration(_ app: Application) {
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
    app.migrations.add(CreateGenreMappings())
    app.migrations.add(CreateFeatured())
}

struct Config {
    static let apiURL = URL(string: "http://localhost:8080/")!

    static let emailAddress: String? = nil
    static let sendgridKey: String? = nil
}

enum Assets {
    case featured
    case posters

    var directory: URL {
        switch self {
        case .featured:
            return Self.publicDirectory.appendingPathComponent("Images/Featured")
        case .posters:
            return Self.publicDirectory.appendingPathComponent("Images/Posters")
        }
    }

    var url: URL {
        switch self {
        case .featured:
            return Config.apiURL.appendingPathComponent("images/featured")
        case .posters:
            return Config.apiURL.appendingPathComponent("images/posters")
        }
    }

    private static var publicDirectory: URL {
        URL(fileURLWithPath: DirectoryConfiguration.detect().publicDirectory)
    }
}
