//
//  MovieAPI.swift
//  
//
//  Created by Marius on 2020-11-04.
//

import Fluent
import Vapor

protocol MovieAPI {
    func fetchMovies(on db: Database) -> EventLoopFuture<Void>
}
