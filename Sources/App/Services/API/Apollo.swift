//
//  Apollo.swift
//  
//
//  Created by Marius on 2022-11-16.
//

import Fluent
import Vapor

struct Apollo: MovieAPI {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func fetchMovies(on db: Database) -> EventLoopFuture<Void> {
        db.eventLoop.makeSucceededVoidFuture()
    }
}

extension Application {
    var apollo: Apollo {
        .init(client: self.client)
    }
}
