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
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: nil)
        sut = Atlantis(client: client)

        XCTAssertThrowsError(try sut.fetchMovies(on: app.db).wait())
    }

    func testFetching() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.valid)
        sut = Atlantis(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 5)
        let showings = try Showing.query(on: app.db).all().wait()
        XCTAssertEqual(showings.count, 6)

        XCTAssertEqual(movies[0].title, "title3D")
        XCTAssertEqual(movies[0].originalTitle, "originalTitle")

        XCTAssertEqual(movies[0].showings[0].city, .siauliai)
        XCTAssertEqual(movies[0].showings[0].date, "2022-12-06 18:50".convertToDate())
        XCTAssertEqual(movies[0].showings[0].venue, .atlantis)
        XCTAssertEqual(movies[0].showings[0].is3D, true)
        XCTAssertEqual(movies[0].showings[0].url, "https://www.atlantiscinemas.lt/velnio-sviesa?sdate=1670284800")
    }

    func testSkipsShowingIfAPIPropertiesAreMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.invalidShowing)
        sut = Atlantis(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 5)
        let showings = try Showing.query(on: app.db).all().wait()
        XCTAssertEqual(showings.count, 5)
    }

    func testSkipsShowingIfAPIPropertiesAresMissing() throws {
        let client = ClientStub(eventLoop: app.eventLoopGroup.next(), data: Data.missingDate)
        sut = Atlantis(client: client)

        try sut.fetchMovies(on: app.db).wait()

        let movies = try Movie.query(on: app.db).with(\.$showings).all().wait()
        XCTAssertEqual(movies.count, 3)
        let showings = try Showing.query(on: app.db).all().wait()
        XCTAssertEqual(showings.count, 4)
    }
    // MARK: Test Helpers

    struct Data {
        static var valid = """
        <div id="sessions_list">
        <dl class="tabs" id="movies">
        <dt id="2022-12-06"><span><strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">06 d.</dt>
        <dd>
        <ul class="movies_list">

        <li class="movie">
        <h3>
        title3D<small>originalTitle</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/velnio-sviesa?sdate=1670284800">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">06 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        18:50</time>
        <span>
        </span>
        </li>

        <li class="movie">
        <h3>
        Negailestinga naktis<small>Violent Night</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/negailestinga-naktis?sdate=1670284800">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">06 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        20:00</time>
        <span>
        </span>
        </li>
        </ul>
        </dd>
        <dt id="2022-12-07"><span><strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</dt>
        <dd>
        <ul class="movies_list">

        <li class="movie">
        <h3>
        Keistas pasaulis (dubliuotas lietuviškai)<small>Strange World</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/keistas-pasaulis?sdate=1670371200">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        10:00</time>
        <span>
        Lietuvių k.</span>
        </div>
        <div class="session">
        <time>
        14:00</time>
        <span>
        Lietuvių k.</span>
        </li>

        <li class="movie">
        <h3>
        Lilas, Lilas, Krokodilas (dubliuotas lietuviškai)<small>Lyle, Lyle, Crocodile</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/lilas-lilas-krokodilas-dubliuotas-lietuviskai?sdate=1670371200">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        11:45</time>
        <span>
        Lietuvių k.</span>
        </li>

        <li class="movie">
        <h3>
        Keistas pasaulis 3D (dubliuotas lietuviškai)<small>Strange World 3D</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/keistas-pasaulis-3d-dubliuotas-lietuviskai?sdate=1670371200">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        12:00</time>
        <span>
        3D
        Lietuvių k.</span>
        </li>
        </ul>
        </dd>
        </dl>
        </div>
        """.data(using: .utf8)!

        static var invalidShowing = """
        <div id="sessions_list">
        <dl class="tabs" id="movies">
        <dt id="2022-12-06"><span><strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">06 d.</dt>
        <dd>
        <ul class="movies_list">

        <li class="movie">
        <h3>
        title3D<small>originalTitle</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/velnio-sviesa?sdate=1670284800">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">06 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        SOMEVALUEFORTESTTOFAIL</time>
        <span>
        </span>
        </li>

        <li class="movie">
        <h3>
        Negailestinga naktis<small>Violent Night</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/negailestinga-naktis?sdate=1670284800">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">06 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        20:00</time>
        <span>
        </span>
        </li>
        </ul>
        </dd>
        <dt id="2022-12-07"><span><strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</dt>
        <dd>
        <ul class="movies_list">

        <li class="movie">
        <h3>
        Keistas pasaulis (dubliuotas lietuviškai)<small>Strange World</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/keistas-pasaulis?sdate=1670371200">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        10:00</time>
        <span>
        Lietuvių k.</span>
        </div>
        <div class="session">
        <time>
        14:00</time>
        <span>
        Lietuvių k.</span>
        </li>

        <li class="movie">
        <h3>
        Lilas, Lilas, Krokodilas (dubliuotas lietuviškai)<small>Lyle, Lyle, Crocodile</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/lilas-lilas-krokodilas-dubliuotas-lietuviskai?sdate=1670371200">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        11:45</time>
        <span>
        Lietuvių k.</span>
        </li>

        <li class="movie">
        <h3>
        Keistas pasaulis 3D (dubliuotas lietuviškai)<small>Strange World 3D</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/keistas-pasaulis-3d-dubliuotas-lietuviskai?sdate=1670371200">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        12:00</time>
        <span>
        3D
        Lietuvių k.</span>
        </li>
        </ul>
        </dd>
        </dl>
        </div>
        """.data(using: .utf8)!

        static var missingDate = """
        <div id="sessions_list">
        <dl class="tabs" id="movies">
        <dt id="2022-12-06"><span><strong>Šiandien</strong><span class="month">Gruodžio</span> <span class="day">06 d.</dt>
        <dd>
        <div class="no-sessions">Šiuo metu negalima įsigyti bilietų 2022-12-06 dienai</div>
        </dd>
        <dt id="2022-12-07"><span><strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</dt>
        <dd>
        <ul class="movies_list">

        <li class="movie">
        <h3>
        Keistas pasaulis (dubliuotas lietuviškai)<small>Strange World</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/keistas-pasaulis?sdate=1670371200">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        10:00</time>
        <span>
        Lietuvių k.</span>
        </div>
        <div class="session">
        <time>
        14:00</time>
        <span>
        Lietuvių k.</span>
        </li>

        <li class="movie">
        <h3>
        Lilas, Lilas, Krokodilas (dubliuotas lietuviškai)<small>Lyle, Lyle, Crocodile</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/lilas-lilas-krokodilas-dubliuotas-lietuviskai?sdate=1670371200">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        11:45</time>
        <span>
        Lietuvių k.</span>
        </li>

        <li class="movie">
        <h3>
        Keistas pasaulis 3D (dubliuotas lietuviškai)<small>Strange World 3D</small>
        </h3>
        </a>
        <div class="buy-button">
        <a class="btn btn-info" href="/keistas-pasaulis-3d-dubliuotas-lietuviskai?sdate=1670371200">
        Pirkti bilietą</a>
        <div class="movie-sessions">
        <div class="sessions-title">
        <strong>Rytoj</strong><span class="month">Gruodžio</span> <span class="day">07 d.</span>
        </div>
        <div class="sessions">
        <div class="session">
        <time>
        12:00</time>
        <span>
        3D
        Lietuvių k.</span>
        </li>
        </ul>
        </dd>
        </dl>
        </div>
        """.data(using: .utf8)!
    }
}
