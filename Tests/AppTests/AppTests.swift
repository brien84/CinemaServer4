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
        try sut.test(.GET, "posters" + "/Example.webp", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.content.contentType, HTTPMediaType.fileExtension("webp"))
        })
    }

    func testUnknownCityParameterThrowsBadRequestError() throws {
        try sut.test(.GET, constructPath(nil, [.forum]), afterResponse: { res in
            XCTAssertEqual(res.status, HTTPResponseStatus.badRequest)
        })
    }

    func testUnknownVenuesParameterThrowsBadRequestError() throws {
        try sut.test(.GET, constructPath(.vilnius, nil), afterResponse: { res in
            XCTAssertEqual(res.status, HTTPResponseStatus.badRequest)
        })
    }

    func testQueryReturnsShowingsOnlyFromSpecifiedCity() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, constructPath(.vilnius, [.apollo, .forum, .multikino]), afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 3)
            XCTAssertEqual(showings.filter({ $0.city == .vilnius }).count, 3)
        })
    }

    func testQueryReturnsShowingsOnlyFromSpecifiedVenues() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, constructPath(.vilnius, [.apollo]), afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .apollo }).count, 1)
        })
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
            XCTAssertEqual(showings.filter({ $0.city == .vilnius }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .kaunas }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .klaipeda }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .siauliai }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .panevezys }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .apollo }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .atlantis }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .forum }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .cinamon }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .multikino }).count, 0)
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
            XCTAssertEqual(showings.filter({ $0.city == .vilnius_ }).count, 3)
            XCTAssertEqual(showings.filter({ $0.venue == .apollo_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .forum_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .multikino_ }).count, 1)
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
            XCTAssertEqual(showings.filter({ $0.city == .kaunas_ }).count, 2)
            XCTAssertEqual(showings.filter({ $0.venue == .cinamon_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .forum_ }).count, 1)
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
            XCTAssertEqual(showings.filter({ $0.city == .klaipeda_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .forum_ }).count, 1)
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
            XCTAssertEqual(showings.filter({ $0.city == .siauliai_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .forum_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .atlantis }).count, 0)
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
            XCTAssertEqual(showings.filter({ $0.city == .panevezys_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .apollo_ }).count, 1)
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
            XCTAssertEqual(showings.filter({ $0.city == .vilnius }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .kaunas }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .klaipeda }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .siauliai }).count, 0)
            XCTAssertEqual(showings.filter({ $0.city == .panevezys }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .apollo }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .atlantis }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .forum }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .cinamon }).count, 0)
            XCTAssertEqual(showings.filter({ $0.venue == .multikino }).count, 0)
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
            XCTAssertEqual(showings.filter({ $0.city == .vilnius_ }).count, 2)
            XCTAssertEqual(showings.filter({ $0.venue == .forum_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .multikino_ }).count, 1)
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
            XCTAssertEqual(showings.filter({ $0.city == .kaunas_ }).count, 2)
            XCTAssertEqual(showings.filter({ $0.venue == .cinamon_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .forum_ }).count, 1)
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
            XCTAssertEqual(showings.filter({ $0.city == .klaipeda_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .forum_ }).count, 1)
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
            XCTAssertEqual(showings.filter({ $0.city == .siauliai_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .forum_ }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .atlantis }).count, 0)
        })
    }

    // MARK: Test Helpers

    func constructPath(_ city: City?, _ venues: [Venue]?) -> String {
        """
        \(city?.rawValue ?? "Kupiškis")/
        \(venues?.map { String($0.rawValue) }.joined(separator: ",") ?? "forum;multi")
        """
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: " ", with: "%20")
    }

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
