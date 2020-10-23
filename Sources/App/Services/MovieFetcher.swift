//
//  MovieFetcher.swift
//  
//
//  Created by Marius on 2020-10-23.
//

import Vapor

protocol MovieFetching {
    func fetch() -> EventLoopFuture<Void>
}

struct MovieFetcher: MovieFetching {
    private var cinamon: Cinamon
    private var forum: ForumCinemas
    private var multikino: Multikino

    init(cinamon: Cinamon, forum: ForumCinemas, multikino: Multikino) {
        self.cinamon = cinamon
        self.forum = forum
        self.multikino = multikino
    }

    func fetch() -> EventLoopFuture<Void> {
        cinamon.fetchMovies().flatMap {
            self.forum.fetchMovies().flatMap {
                self.multikino.fetchMovies()
            }
        }
    }
}

extension Application {
    var movieFetcher: MovieFetcher {
        .init(cinamon: self.cinamon, forum: self.forumCinemas, multikino: self.multikino)
    }
}
