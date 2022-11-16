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
    private var apollo: MovieAPI
    private var cinamon: MovieAPI
    private var forum: MovieAPI
    private var multikino: MovieAPI

    init(apollo: MovieAPI, cinamon: MovieAPI, forum: MovieAPI, multikino: MovieAPI) {
        self.apollo = apollo
        self.cinamon = cinamon
        self.forum = forum
        self.multikino = multikino
    }

    func fetch(on db: Database) -> EventLoopFuture<Void> {
        apollo.fetchMovies(on: db).flatMap {
            cinamon.fetchMovies(on: db).flatMap {
                forum.fetchMovies(on: db).flatMap {
                    multikino.fetchMovies(on: db)
                }
            }
        }
    }
}

extension Application {
    var movieFetcher: MovieFetcher {
        .init(
            apollo: self.apollo,
            cinamon: self.cinamon,
            forum: self.forumCinemas,
            multikino: self.multikino
        )
    }
}
