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
    
}
