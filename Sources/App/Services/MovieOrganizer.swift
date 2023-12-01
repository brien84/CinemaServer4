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
                            mapFeatured(on: db)
                        }
                    }
                }
            }
        }
    }

    private func mapGenres(on db: Database) -> EventLoopFuture<Void> {
        MovieProfile.query(on: db).all().flatMap { movies in
            movies.map { movie in
                mapGenres(on: movie, on: db).flatMap {
                    movie.genres?.sort()
                    return movie.update(on: db)
                }
            }.flatten(on: db.eventLoop)
        }
    }

    private func mapGenres(on movie: MovieProfile, on db: Database) -> EventLoopFuture<Void> {
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
        movie.metadata = profile.metadata
        movie.plot = profile.plot
        movie.trailer = profile.trailer
        movie.poster = getURLForImage(named: movie.originalTitle ?? "", in: .posters)?.absoluteString
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

    /// Deletes all `Movies` that do not have any associated `Showing` children.
    private func cleanup(on db: Database) -> EventLoopFuture<Void> {
        Movie.query(on: db)
            .join(Showing.self, on: \Movie.$id == \Showing.$movie.$id, method: .left)
            .filter(Showing.self, \Showing.$movie.$id == .null)
            .all().flatMap { $0.delete(on: db) }
    }

    private func mapFeatured(on db: Database) -> EventLoopFuture<Void> {
        Featured.query(on: db).all().flatMapEach(on: db.eventLoop) { featured in
            mapFeatured(featured, on: db).flatMap {
                featured.delete(on: db)
            }
        }
    }

    private func mapFeatured(_ featured: Featured, on db: Database) -> EventLoopFuture<Void> {
        return Movie.query(on: db).filter(\.$originalTitle == featured.originalTitle).first().flatMap { movie in
            guard let movie else { return db.eventLoop.makeSucceededFuture(()) }

            let newFeatured = Featured()
            newFeatured.id = UUID()
            newFeatured.label = featured.label
            newFeatured.title = featured.title
            newFeatured.originalTitle = featured.originalTitle
            newFeatured.startDate = featured.startDate
            newFeatured.endDate = featured.endDate
            newFeatured.imageURL = getURLForImage(named: featured.originalTitle, in: .featured)?.absoluteString
            return movie.$featured.create(newFeatured, on: db)
        }
    }

    private func getURLForImage(named name: String, in asset: Assets) -> URL? {
        let name = name.removeSpecialCharacters()
        let paths = FileManager().contentsOfDirectory(asset.directory)
        guard let path = paths.first(where: { $0.lastComponentWithoutExtension == name }) else { return nil }
        return asset.url.appendingPathComponent(path.lastPathComponent)
    }
}

private extension FileManager {
    func contentsOfDirectory(_ directory: URL) -> [URL] {
        do {
            return try contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        } catch {
            fatalError("\(error)")
        }
    }
}

private extension String {
    func removeSpecialCharacters() -> String {
        self.replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "/", with: "")
    }
}

private extension MovieProfile {
    convenience init(from movie: Movie) {
        self.init()
        self.title = movie.title
        self.originalTitle = movie.originalTitle
        self.year = movie.year
        self.duration = movie.duration
        self.ageRating = movie.ageRating
        self.genres = movie.genres
        self.metadata = movie.metadata
        self.plot = movie.plot
        self.trailer = movie.trailer
    }
}

private extension URL {
    /// Returns last path component of the `URL` without its file extension.
    ///
    /// Example:
    /// ```
    /// let fileURL = URL(fileURLWithPath: "Public/Posters/Example.png")
    /// print(fileURL.lastComponentWithoutExtension) // prints "Example"
    /// ```
    var lastComponentWithoutExtension: String {
        self.deletingPathExtension().lastPathComponent
    }
}
