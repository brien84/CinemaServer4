//
//  Application+Testable.swift
//  
//
//  Created by Marius on 2020-09-21.
//

import App
import Vapor

extension Application {
    static func testable() throws -> Application {
        let app = Application(.testing)
        try configure(app)

        try app.autoRevert().wait()
        try app.autoMigrate().wait()

        return app
    }
}
