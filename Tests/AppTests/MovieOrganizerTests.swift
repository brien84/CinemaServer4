//
//  MovieOrganizerTests.swift
//  
//
//  Created by Marius on 2020-10-25.
//

@testable import App
import XCTVapor

final class MovieOrganizerTests: XCTestCase {
    var app: Application!
    var sut: MovieOrganizer!

    override func setUp() {
        app = try! Application.testable()
        sut = MovieOrganizer()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }

    func testMappingOriginalTitles() throws {
        let currentTitle = "TestTitle"
        let newTitle = "NewTestTitle"
        Movie.create(originalTitle: currentTitle, on: app.db)
        TitleMapping.create(originalTitle: currentTitle, newOriginalTitle: newTitle, on: app.db)

        _ = try sut.organize(on: app.db).wait()

        let movies = try Movie.query(on: app.db).all().wait()

        XCTAssertEqual(movies.count, 1)
        XCTAssertEqual(movies[0].originalTitle, newTitle)
    }

}
