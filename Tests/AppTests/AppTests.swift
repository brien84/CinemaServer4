@testable import App
import Fluent
import XCTVapor

final class AppTests: XCTestCase {
    var sut: Application!

    override func setUp() {
        sut = try! Application.testable()
    }

    override func tearDown() {
        sut.shutdown()
    }

    func testFeaturedImageRoute() throws {
        try sut.test(.GET, "images/featured" + "/Example.webp", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.content.contentType, HTTPMediaType.fileExtension("webp"))
        })
    }

    func testPosterImageRoute() throws {
        try sut.test(.GET, "images/posters" + "/Example.webp", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.content.contentType, HTTPMediaType.fileExtension("webp"))
        })
    }

    func testQueryReturnsFeaturedFromSpecifiedCityAndVenus() throws {
        let startDate = Date()
        let endDate = startDate.advanced(by: 10000)

        let featured0 = Featured(originalTitle: "Test0", startDate: startDate, endDate: endDate, imageURL: "")
        let featured1 = Featured(originalTitle: "Test1", startDate: startDate, endDate: endDate, imageURL: "")

        Movie.create(originalTitle: "Test0", showings: [Showing(city: .vilnius, venue: .forum)], on: sut.db)
        let movie0 = try! Movie.query(on: sut.db).filter(\.$originalTitle == "Test0").first().wait()
        try! movie0!.$featured.create(featured0, on: sut.db).wait()

        Movie.create(originalTitle: "Test1", showings: [Showing(city: .vilnius, venue: .multikino)], on: sut.db)
        let movie1 = try! Movie.query(on: sut.db).filter(\.$originalTitle == "Test1").first().wait()
        try! movie1!.$featured.create(featured1, on: sut.db).wait()

        try sut.test(.GET, constructFeaturedPath(.vilnius, [.multikino]), afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let featured = try res.content.decode([Featured].self)
            XCTAssertEqual(featured.count, 1)
            XCTAssertEqual(featured.first!.originalTitle, "Test1")
        })
    }

    func testQueryReturnsOnlyValidFeatured() throws {
        let now = Date()

        // invalid because `startDate` is in the future.
        let featured0 = Featured(
            originalTitle: "Test0",
            startDate: now.advanced(by: 100),
            endDate: now.advanced(by: 101),
            imageURL: ""
        )

        // invalind because `endDate` is in the past.
        let featured1 = Featured(
            originalTitle: "Test1",
            startDate: now.advanced(by: -101),
            endDate: now.advanced(by: -100),
            imageURL: ""
        )

        // invalind because `imageURL` is nil.
        let featured2 = Featured(
            originalTitle: "Test2",
            startDate: now.advanced(by: -100),
            endDate: now.advanced(by: 100),
            imageURL: nil
        )

        let featured3 = Featured(
            originalTitle: "Test3",
            startDate: now.advanced(by: -100),
            endDate: now.advanced(by: 100),
            imageURL: ""
        )

        Movie.create(originalTitle: "Test0", showings: [Showing(city: .vilnius, venue: .forum)], on: sut.db)
        let movie0 = try! Movie.query(on: sut.db).filter(\.$originalTitle == "Test0").first().wait()
        try! movie0!.$featured.create(featured0, on: sut.db).wait()

        Movie.create(originalTitle: "Test1", showings: [Showing(city: .vilnius, venue: .forum)], on: sut.db)
        let movie1 = try! Movie.query(on: sut.db).filter(\.$originalTitle == "Test1").first().wait()
        try! movie1!.$featured.create(featured1, on: sut.db).wait()

        Movie.create(originalTitle: "Test2", showings: [Showing(city: .vilnius, venue: .forum)], on: sut.db)
        let movie2 = try! Movie.query(on: sut.db).filter(\.$originalTitle == "Test2").first().wait()
        try! movie2!.$featured.create(featured2, on: sut.db).wait()

        Movie.create(originalTitle: "Test3", showings: [Showing(city: .vilnius, venue: .forum)], on: sut.db)
        let movie3 = try! Movie.query(on: sut.db).filter(\.$originalTitle == "Test3").first().wait()
        try! movie3!.$featured.create(featured3, on: sut.db).wait()

        try sut.test(.GET, constructFeaturedPath(.vilnius, [.forum]), afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let featured = try res.content.decode([Featured].self)
            XCTAssertEqual(featured.count, 1)
            XCTAssertEqual(featured.first!.originalTitle, "Test3")
        })
    }

    func testQueryReturnsFeaturedSortedByLatestStartDate() throws {
        let now = Date()
        let endDate = now.advanced(by: 10000)

        let featured0 = Featured(originalTitle: "Test0", startDate: now.advanced(by: -50), endDate: endDate, imageURL: "")
        let featured1 = Featured(originalTitle: "Test1", startDate: now.advanced(by: -10), endDate: endDate, imageURL: "")
        let featured2 = Featured(originalTitle: "Test2", startDate: now.advanced(by: -30), endDate: endDate, imageURL: "")

        Movie.create(originalTitle: "Test0", showings: [Showing(city: .vilnius, venue: .forum)], on: sut.db)
        let movie0 = try! Movie.query(on: sut.db).filter(\.$originalTitle == "Test0").first().wait()
        try! movie0!.$featured.create(featured0, on: sut.db).wait()

        Movie.create(originalTitle: "Test1", showings: [Showing(city: .vilnius, venue: .forum)], on: sut.db)
        let movie1 = try! Movie.query(on: sut.db).filter(\.$originalTitle == "Test1").first().wait()
        try! movie1!.$featured.create(featured1, on: sut.db).wait()

        Movie.create(originalTitle: "Test2", showings: [Showing(city: .vilnius, venue: .forum)], on: sut.db)
        let movie2 = try! Movie.query(on: sut.db).filter(\.$originalTitle == "Test2").first().wait()
        try! movie2!.$featured.create(featured2, on: sut.db).wait()

        try sut.test(.GET, constructFeaturedPath(.vilnius, [.forum]), afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let featured = try res.content.decode([Featured].self)
            XCTAssertEqual(featured.count, 3)
            XCTAssertEqual(featured, [featured1, featured2, featured0])
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

    func testQueryReturnsShowingsFromSpecifiedCity() throws {
        Movie.create(showings: showings, on: sut.db)

        let venues: [Venue] = [.apolloAkropolis, .apolloOutlet, .forum, .multikino]
        try sut.test(.GET, constructPath(.vilnius, venues), afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 4)
            XCTAssertEqual(showings.filter({ $0.city == .vilnius }).count, 4)
        })
    }

    func testQueryReturnsShowingsFromSpecifiedVenues() throws {
        Movie.create(showings: showings, on: sut.db)

        try sut.test(.GET, constructPath(.vilnius, [.forum]), afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)

            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .forum }).count, 1)
        })
    }

    // MARK: v1.4 - Deprecated

    func testLegacyQueryInVilnius() throws {
        Movie.create(showings: [Showing(city: .vilnius, venue: .apolloAkropolis)], on: sut.db)

        let headers = HTTPHeaders([("iOS-Client-Version", "1.4")])
        try sut.test(.GET, constructPath(.vilnius, [.apollo]), headers: headers, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)

            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)
            
            let service = try res.content.decode([ShowingService].self)
            let showings = service.flatMap { $0.showings }
            XCTAssertEqual(showings.count, 1)
            XCTAssertEqual(showings.filter({ $0.city == .vilnius }).count, 1)
            XCTAssertEqual(showings.filter({ $0.venue == .apollo }).count, 1)
        })
    }

    // MARK: v1.2 - Deprecated

    func testUpdateRoute() throws {
        try sut.test(.GET, "update", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)

            let version = try res.content.decode(String.self)

            XCTAssertEqual(version, "1.3")
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
        \(city?.rawValue ?? "Miestas")/
        \(venues?.map { String($0.rawValue) }.joined(separator: ",") ?? "forum;multi")
        """
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: " ", with: "%20")
    }

    func constructFeaturedPath(_ city: City?, _ venues: [Venue]?) -> String {
        """
        featured/
        \(city?.rawValue ?? "Miestas")/
        \(venues?.map { String($0.rawValue) }.joined(separator: ",") ?? "forum;multi")
        """
        .replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: " ", with: "%20")
    }

    let showings = [
        Showing(city: .vilnius, venue: .apolloAkropolis),
        Showing(city: .vilnius, venue: .apolloOutlet),
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
