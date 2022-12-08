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

    func testPostersRoute() throws {
        try sut.test(.GET, Route.posters.description + "/example.png", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.content.contentType, HTTPMediaType.png)
        })
    }

    func testAllRoute() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, Route.Movie.all.path.description + "/" + SupportedVersion.v1_3.rawValue, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 9)
        })
    }

    func testVilniusRoute() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, Route.Movie.vilnius.path.description + "/" + SupportedVersion.v1_3.rawValue, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 3)
            XCTAssertEqual(showings.filter({ $0.city == .vilnius }).count, 3)
        })
    }

    func testKaunasRoute() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, Route.Movie.kaunas.path.description + "/" + SupportedVersion.v1_3.rawValue, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 2)
            XCTAssertEqual(showings.filter({ $0.city == .kaunas }).count, 2)
        })
    }

    func testKlaipedaRoute() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, Route.Movie.klaipeda.path.description + "/" + SupportedVersion.v1_3.rawValue, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings.filter({ $0.city == .klaipeda }).count, 1)
        })
    }

    func testSiauliaiRoute() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, Route.Movie.siauliai.path.description + "/" + SupportedVersion.v1_3.rawValue, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 2)
            XCTAssertEqual(showings.filter({ $0.city == .siauliai }).count, 2)
        })
    }

    func testPanevezysRoute() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, Route.Movie.panevezys.path.description + "/" + SupportedVersion.v1_3.rawValue, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings.filter({ $0.city == .panevezys }).count, 1)
        })
    }

    func testRoutesWithUnknownVersionParameterReturnErrorStatus() throws {
        try Route.Movie.allCases.forEach {
            try sut.test(.GET, ("\($0.path)/TESTFAIL"), afterResponse: { res in
                XCTAssertEqual(res.status, SupportedVersion.error.status)
            })
        }
    }

    // MARK: v1.2 - Deprecated

    func testAllRoute_v1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "all_", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 8)
            XCTAssertEqual(showings.filter({ $0.venue == .atlantis }).count, 0)
        })
    }

    func testVilniusRoute_v1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "vilnius_", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 3)
            XCTAssertEqual(showings.filter({ $0.city == .vilnius }).count, 3)
        })
    }

    func testKaunasRoute_v1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "kaunas_", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 2)
            XCTAssertEqual(showings.filter({ $0.city != .kaunas }).count, 0)
        })
    }

    func testKlaipedaRoute_v1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "klaipeda_", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings.filter({ $0.city == .klaipeda }).count, 1)
        })
    }

    func testSiauliaiRoute_v1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "siauliai_", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .atlantis }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .siauliai }).count, 1)
        })
    }

    func testPanevezysRoute_v1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "panevezys_", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings.filter({ $0.city == .panevezys }).count, 1)
        })
    }

    func testUpdateRoute() throws {
        try sut.test(.GET, "update", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let version = try res.content.decode(String.self)

            XCTAssertEqual(version, "1.1.2")
        })
    }

    // MARK: v1.1.2 - Deprecated

    func testAllRoute_v1_1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "all", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 6)
            XCTAssertEqual(showings.filter({ $0.venue == .apollo }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .atlantis }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .panevezys }).count, 0)
        })
    }

    func testVilniusRoute_v1_1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "vilnius", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 2)
            XCTAssertEqual(showings.filter({ $0.venue == .apollo }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .vilnius }).count, 2)
        })
    }

    func testKaunasRoute_v1_1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "kaunas", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 2)
            XCTAssertEqual(showings.filter({ $0.city == .kaunas }).count, 2)
        })
    }

    func testKlaipedaRoute_v1_1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "klaipeda", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings.filter({ $0.city == .klaipeda }).count, 1)
        })
    }

    func testSiauliaiRoute_v1_1_2() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, "siauliai", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .atlantis }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .siauliai }).count, 1)
        })
    }

    // MARK: Test Helpers

    let showings = [
        Showing(city: .vilnius, venue: .apollo),
        Showing(city: .vilnius, venue: .forum),
        Showing(city: .vilnius, venue: .multikino),
        Showing(city: .kaunas, venue: .cinamon),
        Showing(city: .kaunas, venue: .forum),
        Showing(city: .klaipeda, venue: .forum),
        Showing(city: .siauliai, venue: .atlantis),
        Showing(city: .siauliai, venue: .forum),
        Showing(city: .panevezys, venue: .apollo),
    ]

    struct ShowingService: Codable {
        var showings: [Showing]
    }
}
