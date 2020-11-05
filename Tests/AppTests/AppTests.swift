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
        Movie.create(title: "", originalTitle: "", year: "", duration: "",
                     ageRating: "", genres: [], plot: "", poster: "", on: sut.db)

        try sut.test(.GET, "all") { res in
            XCTAssertEqual(res.status, .ok)
            let movies = try res.content.decode([Movie].self)
            XCTAssertEqual(movies.count, 1)
        }
    }

    func testPostersRoute() throws {
        try sut.test(.GET, "posters/example.png") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.content.contentType, HTTPMediaType.png)

        }
    }
}
