//
//  MovieFetcher.swift
//  
//
//  Created by Marius on 2020-10-23.
//

import Fluent
import Vapor

protocol MovieFetching {
    func fetch(on db: Database) -> EventLoopFuture<Void>
}

struct MovieFetcher: MovieFetching {
    private var cinamon: MovieAPI
    private var forum: MovieAPI
    private var multikino: MovieAPI

    init(cinamon: MovieAPI, forum: MovieAPI, multikino: MovieAPI) {
        self.cinamon = cinamon
        self.forum = forum
        self.multikino = multikino
    }

    func fetch(on db: Database) -> EventLoopFuture<Void> {
        cinamon.fetchMovies(on: db).flatMap {
            self.forum.fetchMovies(on: db).flatMap {
                self.multikino.fetchMovies(on: db)
            }
        }
    }
}

extension Application {
    var movieFetcher: MovieFetcher {
        .init(cinamon: self.cinamon, forum: self.forumCinemas, multikino: self.multikino)
    }
}
