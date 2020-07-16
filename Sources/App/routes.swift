import Vapor

func routes(_ app: Application) throws {
    app.get("all") { req in
        Movie.query(on: req.db).all()
    }

    app.get("posters", ":fileName") { req -> Response in
        let fileName = req.parameters.get("fileName")
        let path = "\(DirectoryConfiguration.detect().publicDirectory)Posters/" + (fileName ?? "")
        return req.fileio.streamFile(at: path)
    }
}
