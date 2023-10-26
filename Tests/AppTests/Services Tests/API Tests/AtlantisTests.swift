//
//  AtlantisTests.swift
//  
//
//  Created by Marius on 2022-12-07.
//

@testable import App
import XCTVapor

final class AtlantisTests: XCTestCase {
    var app: Application!
    var sut: Atlantis!

    override func setUp() {
        app = try! Application.testable()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testFetchingBadResponseThrowsError() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.any(), data: nil)
        sut = Atlantis(client: client)

        XCTAssertThrowsError(try sut.fetchMovies(on: app.db).wait())
    }

    func testFetching() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.any(), data: Data.valid)
        sut = Atlantis(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 3)
        let showings = try Showing.query(on: app.db).all().wait()
        XCTAssertEqual(showings.count, 4)

        XCTAssertEqual(movies[0].title, "title3D")
        XCTAssertEqual(movies[0].originalTitle, "originalTitle")
        XCTAssertEqual(movies[0].ageRating, .v)
        XCTAssertEqual(movies[0].genres, ["Trileris", "Siaubo"])

        XCTAssertEqual(movies[0].showings[0].city, .siauliai)
        XCTAssertEqual(movies[0].showings[0].date, "2022-12-10 11:45".convertToDate())
        XCTAssertEqual(movies[0].showings[0].venue, .atlantis)
        XCTAssertEqual(movies[0].showings[0].is3D, true)
        XCTAssertEqual(movies[0].showings[0].url, "https://www.atlantiscinemas.lt/?sdate=1670284800")
    }

    func testShowingWithInvalidTimeIsIgnored() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.any(), data: Data.invalidShowing)
        sut = Atlantis(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        let showings = try Showing.query(on: app.db).all().wait()
        XCTAssertEqual(showings.count, 1)
    }

    func testParsingDoesNotFailWhenAPIContainsDateWithoutData() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.any(), data: Data.missingDate)
        sut = Atlantis(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 1)
        let showings = try Showing.query(on: app.db).all().wait()
        XCTAssertEqual(showings.count, 1)
        XCTAssertEqual(movies[0].showings[0].date, "2022-12-22 10:00".convertToDate())
    }

    // MARK: Test Helpers

    struct Data {
        static var valid = """
        <dl class="tabs" id="movies">
        <dt id="2022-12-10"><span><strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">10 d.</span></span></dt>
        <dd><ul class="movies_list">

        <li class="movie">
        <div class="movie-ticket">
        <div class="movie-info-header">
        <div class="genre">Trileris, Siaubo</div>
        <div class="age-class">V</div>
        <div class="clearfix"></div>
        </div><a href="/lilas-lilas-krokodilas-dubliuotas-lietuviskai?sdate=1670630400""></a>
        <div class="movie-info"><div class="movie-info-details">
        <a href="/lilas-lilas-krokodilas-dubliuotas-lietuviskai?sdate=1670630400">
        <h3>title3D<small>originalTitle</small></h3></a>
        <div class="buy-button"><a class="btn btn-info" href="/?sdate=1670284800">Pirkti bilietą</a></div>
        <div class="short-description">
        <p>Primų šeimai persikėlus į Niujorką, jų sūnus Džošas sunkiai pritampa naujoje vietoje.</p>
        </div>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">10 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>11:45</time>
        <span>Lietuvių k.</span>
        </div>
        <div class="session">
        <time>14:00</time>
        <span>Lietuvių k.</span>
        </div>
        <div class="clearfix"></div>
        </div></div></div></div><div class="clearfix"></div></div>
        </li>

        <li class="movie">
        <div class="movie-ticket">
        <div class="movie-info-header">
        <div class="genre">Animacinis filmas visai šeimai</div>
        <div class="age-class">V</div>
        <div class="clearfix"></div>
        </div><a href="/keistas-pasaulis?sdate=1670630400" class="movie-cover" style="background:"></a>
        <div class="movie-info"><div class="movie-info-details">
        <a href="/keistas-pasaulis?sdate=1670630400">
        <h3>Keistas pasaulis<small>Strange World</small></h3></a>
        <div class="buy-button"><a class="btn btn-info" href="/?sdate=1670630400">Pirkti bilietą</a></div>
        <div class="short-description">
        <p>Originali kino studijos „Disney“ veiksmo kupina animacija.</p>
        </div>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">10 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>13:20</time>
        <span>Lietuvių k.</span>
        </div>
        <div class="clearfix"></div>
        </div></div></div></div><div class="clearfix"></div></div>
        </li>

        </ul><div class="clearfix"></div></dd>

        <dt id="2022-12-11"><span><strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">11 d.</span></span></dt>
        <dd><ul class="movies_list">

        <li class="movie">
        <div class="movie-ticket">
        <div class="movie-info-header">
        <div class="genre">Animacinis filmas visai šeimai</div>
        <div class="age-class">V</div>
        <div class="clearfix"></div>
        </div><a href="/keistas-pasaulis?sdate=1670716800" class="movie-cover" style="background:"></a>
        <div class="movie-info"><div class="movie-info-details">
        <a href="/keistas-pasaulis?sdate=1670716800">
        <h3>Rojaus miestas<small>Paradise City</small></h3></a>
        <div class="buy-button"><a class="btn btn-info" href="/?sdate=1670716800">Pirkti bilietą</a></div>
        <div class="short-description">
        <p>Originali kino studijos „Disney“ veiksmo kupina animacija supažindina.</p>
        </div>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">11 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>10:00</time>
        <span>Lietuvių k.</span></div>
        <div class="clearfix"></div>
        </div></div></div></div><div class="clearfix"></div></div>
        </li>

        </ul><div class="clearfix"></div></dd>
        """.data(using: .utf8)!

        static var invalidShowing = """
        <dl class="tabs" id="movies">

        <dt id="2022-12-11"><span><strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">11 d.</span></span></dt>
        <dd><ul class="movies_list">

        <li class="movie">
        <div class="movie-ticket">
        <div class="movie-info-header">
        <div class="genre">Nuotykių filmas visai šeimai</div>
        <div class="age-class">V</div>
        <div class="clearfix"></div>
        </div><a href="/lilas-lilas-krokodilas-dubliuotas-lietuviskai?sdate=1670630400""></a>
        <div class="movie-info"><div class="movie-info-details">
        <a href="/lilas-lilas-krokodilas-dubliuotas-lietuviskai?sdate=1670630400">
        <h3>title3D<small>originalTitle</small></h3></a>
        <div class="buy-button"><a class="btn btn-info" href="/?sdate=1670284800">Pirkti bilietą</a></div>
        <div class="short-description">
        <p>Primų šeimai persikėlus į Niujorką, jų sūnus Džošas sunkiai pritampa naujoje vietoje.</p>
        </div>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">10 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>INVALID-VALUE-TEST-FAIL</time>
        <span>Lietuvių k.</span>
        </div>
        <div class="session">
        <time>14:00</time>
        <span>Lietuvių k.</span>
        </div>
        <div class="clearfix"></div>
        </div></div></div></div><div class="clearfix"></div></div>
        </li>

        </ul><div class="clearfix"></div></dd>

        """.data(using: .utf8)!

        static var missingDate = """
        <dl class="tabs" id="movies">
        <dt id="2022-12-09"><span><strong>Penktadienis</strong><span class="month">Gruodžio</span> <span class="day">09 d.</span></span></dt>
        <dd>
        <div class="no-sessions">Šiuo metu negalima įsigyti bilietų 2022-12-09 dienai</div>
        </dd>

        <dt id="2022-12-10"><span><strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">10 d.</span></span></dt>
        <dd><ul class="movies_list">

        <li class="movie">
        <div class="movie-ticket">
        <div class="movie-info-header">
        <div class="genre">Animacinis filmas visai šeimai</div>
        <div class="age-class">V</div>
        <div class="clearfix"></div>
        </div><a href="/keistas-pasaulis?sdate=1671667200" class="movie-cover" style="background:"></a>
        <div class="movie-info"><div class="movie-info-details">
        <a href="/keistas-pasaulis?sdate=1671667200">
        <h3>Rojaus miestas<small>Paradise City</small></h3></a>
        <div class="buy-button"><a class="btn btn-info" href="/?sdate=1671667200">Pirkti bilietą</a></div>
        <div class="short-description">
        <p>Originali kino studijos „Disney“ veiksmo kupina animacija supažindina.</p>
        </div>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">11 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>10:00</time>
        <span>Lietuvių k.</span></div>
        <div class="clearfix"></div>
        </div></div></div></div><div class="clearfix"></div></div>
        </li>

        </ul><div class="clearfix"></div></dd>
        """.data(using: .utf8)!
    }
}
