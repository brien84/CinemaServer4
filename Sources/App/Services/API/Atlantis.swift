//
//  Atlantis.swift
//  
//
//  Created by Marius on 2022-12-07.
//

import Fluent
import Vapor

struct Atlantis: MovieAPI {
    private let client: Client
    
    init(client: Client) {
        self.client = client
    }

    func fetchMovies(on db: Database) -> EventLoopFuture<Void> {
        db.eventLoop.makeSucceededVoidFuture()
    }
}

extension Application {
    var atlantis: Atlantis {
        .init(client: self.client)
    }
}
