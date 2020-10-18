//
//  ForumCinemasTests.swift
//  
//
//  Created by Marius on 2020-09-26.
//

@testable import App
import XCTVapor

final class ForumCinemasTests: XCTestCase {
    var app: Application!
    var sut: ForumCinemas!

    override func setUp() {
        app = try! Application.testable()
    }

    override func tearDown() {
        sut = nil
        app.shutdown()
    }
}
