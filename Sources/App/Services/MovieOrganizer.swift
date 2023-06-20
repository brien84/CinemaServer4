//
//  MovieOrganizer.swift
//
//
//  Created by Marius on 2020-10-25.
//

import Fluent
import Vapor

protocol MovieOrganization {
    func organize(on db: Database) -> EventLoopFuture<Void>
}

struct MovieOrganizer: MovieOrganization {
    func organize(on db: Database) -> EventLoopFuture<Void> {
        mapGenres(on: db).flatMap {
            mapOriginalTitles(on: db).flatMap {
                applyProfiles(on: db).flatMap {
                    mapMovieShowings(on: db).flatMap {
                        cleanup(on: db).flatMap {
                            setPosters(on: db)
                        }
                    }
                }
            }
        }
    }

    private func mapGenres(on db: Database) -> EventLoopFuture<Void> {
        Movie.query(on: db).all().flatMap { movies in
            movies.map { movie in
                mapGenres(on: movie, on: db).flatMap {
                    movie.genres?.sort()
                    return movie.update(on: db)
                }
            }.flatten(on: db.eventLoop)
        }
    }

    private func mapGenres(on movie: Movie, on db: Database) -> EventLoopFuture<Void> {
        return GenreMapping.query(on: db).all().flatMap { mappings in
            mappings.map { mapping in
                if let index = movie.genres?.firstIndex(of: mapping.genre) {
                    movie.genres?[index] = mapping.newGenre
                    return movie.update(on: db)
                } else {
                    return db.eventLoop.makeSucceededFuture(())
                }
            }.flatten(on: db.eventLoop)
        }
    }

    private func mapOriginalTitles(on db: Database) -> EventLoopFuture<Void> {
        Movie.query(on: db).all().flatMap { movies in
            movies.map { movie in
                mapOriginalTitle(on: movie, on: db)
            }.flatten(on: db.eventLoop)
        }
    }

    private func mapOriginalTitle(on movie: Movie, on db: Database) -> EventLoopFuture<Void> {
        guard let title = movie.originalTitle else {
            return db.eventLoop.makeSucceededFuture(())
        }

        return TitleMapping.query(on: db).filter(\.$originalTitle == title).first().flatMap { mapping in
            guard let mapping = mapping else {
                return db.eventLoop.makeSucceededFuture(())
            }

            movie.originalTitle = mapping.newOriginalTitle
            return movie.update(on: db)
        }
    }

    private func applyProfiles(on db: Database) -> EventLoopFuture<Void> {
        Movie.query(on: db).all().flatMap { movies in
            movies.map { movie in
                applyProfile(on: movie, on: db)
            }.flatten(on: db.eventLoop)
        }
    }

    /// Finds and applies `MovieProfile` on a `movie` or creates a new profile if it does not exist.
    private func applyProfile(on movie: Movie, on db: Database) -> EventLoopFuture<Void> {
        MovieProfile.query(on: db).filter(\.$originalTitle == movie.originalTitle).first().flatMap { profile in
            if let profile = profile {
                return apply(profile: profile, on: movie, on: db)
            } else {
                return MovieProfile(from: movie).save(on: db)
            }
        }
    }

    private func apply(profile: MovieProfile, on movie: Movie, on db: Database) -> EventLoopFuture<Void> {
        movie.title = profile.title
        movie.year = profile.year
        movie.duration = profile.duration
        movie.ageRating = profile.ageRating
        movie.genres = profile.genres
        movie.plot = profile.plot

        return movie.update(on: db)
    }

    private func mapMovieShowings(on db: Database) -> EventLoopFuture<Void> {
        Movie.query(on: db).unique().all(\.$originalTitle).flatMap { titles in
            titles.map { title in
                Movie.query(on: db).filter(\.$originalTitle == title).all().flatMap { movies in
                    if movies.count > 1, let title = title {
                        return mapMovieShowings(with: title, on: db)
                    } else {
                        return db.eventLoop.makeSucceededFuture(())
                    }
                }
            }.flatten(on: db.eventLoop)
        }
    }

    /// Maps showings from movies with same `originalTitle` to a single parent movie.
    ///
    /// - Attention: This method does not delete movies, which are left without showings. Call `cleanup()` method afterwards!
    private func mapMovieShowings(with originalTitle: String, on db: Database) -> EventLoopFuture<Void> {
        Showing.query(on: db)
            .join(Movie.self, on: \Showing.$movie.$id == \Movie.$id, method: .left)
            .filter(Movie.self, \.$originalTitle == originalTitle)
            .all().flatMap { showings in

                guard let id = showings.first?.$movie.id
                    else { return db.eventLoop.makeSucceededFuture(()) }

                return showings.map { showing in
                    showing.$movie.id = id
                    return showing.update(on: db)
                }.flatten(on: db.eventLoop)
        }
    }

    /// Deletes `Movies`, which do not have any `Showing` children.
    private func cleanup(on db: Database) -> EventLoopFuture<Void> {
        Movie.query(on: db)
            .join(Showing.self, on: \Movie.$id == \Showing.$movie.$id, method: .left)
            .filter(Showing.self, \Showing.$movie.$id == .null)
            .all().flatMap { $0.delete(on: db) }
    }

    private func setPosters(on db: Database) -> EventLoopFuture<Void> {
        Movie.query(on: db).all().flatMap { movies in
            movies.map { movie in
                setPoster(on: movie, on: db)
            }.flatten(on: db.eventLoop)
        }
    }

    /// Poster images are located in `Public/Posters`. Image names should be the same as `originalTitle` property.
    private func setPoster(on movie: Movie, on db: Database) -> EventLoopFuture<Void> {
        let originalTitle = movie.originalTitle?
                .replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: "?", with: "")
                .replacingOccurrences(of: "/", with: "")
                .lowercased()

        let publicDirectory = URL(fileURLWithPath: "\(DirectoryConfiguration.detect().publicDirectory)Posters")
        guard let posterPaths = try? FileManager().contentsOfDirectory(at: publicDirectory, includingPropertiesForKeys: nil)
            else { fatalError("Error while loading posters!") }

        if let posterPath = posterPaths.first(where: { $0.fileNameWithoutExtension == originalTitle }) {
            let url = Config.postersURL?.appendingPathComponent(posterPath.lastPathComponent)
            movie.poster = url?.absoluteString
            return movie.update(on: db)
        } else {
            return db.eventLoop.makeSucceededFuture(())
        }
    }
}

extension URL {
    /// "Public/Posters/Example.png" -> "example"
    fileprivate var fileNameWithoutExtension: String {
        self.deletingPathExtension().lastPathComponent.lowercased()
    }
}
