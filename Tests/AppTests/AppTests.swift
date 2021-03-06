@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    var sut: Application!

    override func setUp() {
        sut = try! Application.testable()
    }

    override func tearDown() {
        sut.shutdown()
    }

    func testAllRoute() throws {
        let showing = Showing(city: .vilnius, date: Date(), venue: "", is3D: false, url: "")
        Movie.create(title: "", originalTitle: "", year: "", duration: "", ageRating: "",
                     genres: [], plot: "", poster: "", showings: [showing], on: sut.db)

        try sut.test(.GET, "all", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
        })
    }

    func testVilniusRoute() throws {
        let showings = [Showing(city: .vilnius, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .kaunas, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .klaipeda, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .siauliai, date: Date(), venue: "", is3D: false, url: "")]

        Movie.create(title: "", originalTitle: "", year: "", duration: "", ageRating: "",
                     genres: [], plot: "", poster: "", showings: showings, on: sut.db)

        try sut.test(.GET, "vilnius", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings[0].city, .vilnius)
        })
    }

    func testKaunasRoute() throws {
        let showings = [Showing(city: .vilnius, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .kaunas, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .klaipeda, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .siauliai, date: Date(), venue: "", is3D: false, url: "")]

        Movie.create(title: "", originalTitle: "", year: "", duration: "", ageRating: "",
                     genres: [], plot: "", poster: "", showings: showings, on: sut.db)

        try sut.test(.GET, "kaunas", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings[0].city, .kaunas)
        })
    }

    func testKlaipedaRoute() throws {
        let showings = [Showing(city: .vilnius, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .kaunas, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .klaipeda, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .siauliai, date: Date(), venue: "", is3D: false, url: "")]

        Movie.create(title: "", originalTitle: "", year: "", duration: "", ageRating: "",
                     genres: [], plot: "", poster: "", showings: showings, on: sut.db)

        try sut.test(.GET, "klaipeda", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings[0].city, .klaipeda)
        })
    }

    func testSiauliaiRoute() throws {
        let showings = [Showing(city: .vilnius, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .kaunas, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .klaipeda, date: Date(), venue: "", is3D: false, url: ""),
                        Showing(city: .siauliai, date: Date(), venue: "", is3D: false, url: "")]

        Movie.create(title: "", originalTitle: "", year: "", duration: "", ageRating: "",
                     genres: [], plot: "", poster: "", showings: showings, on: sut.db)

        try sut.test(.GET, "siauliai", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings[0].city, .siauliai)
        })
    }

    func testPostersRoute() throws {
        try sut.test(.GET, "posters/example.png", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.content.contentType, HTTPMediaType.png)
        })
    }

    // MARK: Test Helpers

    struct ShowingService: Codable {
        var showings: [Showing]
    }
}
