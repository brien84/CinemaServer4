//
//  MainController.swift
//  
//
//  Created by Marius on 2020-07-07.
//

import Vapor

struct MainController {
    private var app: Application

    private var forum: ForumCinemas
    private var multikino: Multikino
    private var cinamon: Cinamon

    init(app: Application) {
        self.app = app
        self.forum = app.forumCinemas
        self.multikino = app.multikino
        self.cinamon = app.cinamon
    }

    func start() {
        getMovies().whenSuccess {
            print($0.count)
        }
    }

    private func getMovies() -> EventLoopFuture<[Movie]> {
        forum.getMovies().flatMap { forumMovies in
            self.multikino.getMovies().flatMap { multiMovies in
                self.cinamon.getMovies().map { cinamonMovies -> [Movie] in
                    var movies = [Movie]()

                    movies.append(contentsOf: forumMovies)
                    movies.append(contentsOf: multiMovies)
                    movies.append(contentsOf: cinamonMovies)

                    return movies
                }
            }
        }
    }
}
