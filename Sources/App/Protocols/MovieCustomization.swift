//
//  MovieCustomization.swift
//  
//
//  Created by Marius on 2020-07-08.
//

import Vapor

protocol MovieCustomization {
    func applyProfile(to movie: Movie) -> Movie
    func customizeOriginalTitle(for movie: Movie) -> Movie
}

extension MovieCustomization {
    // Replaces values of `Movie` properties with new values from `Profiles.plist` file.
    func applyProfile(to movie: Movie) -> Movie {
        guard let profiles = loadProfiles() else { fatalError("Could not open `Profiles.plist`!") }

        guard let originalTitle = movie.originalTitle else { return movie }
        guard let profile = profiles[originalTitle] as? [String: AnyObject] else { return movie }

        if let title = profile["title"] as? String {
            movie.title = title
        }

        if let year = profile["year"] as? String {
            movie.year = year
        }

        if let duration = profile["duration"] as? String {
            movie.duration = duration
        }

        if let ageRating = profile["ageRating"] as? String {
            movie.ageRating = ageRating
        }

        if let genres = profile["genres"] as? [String] {
            movie.genres = genres
        }

        if let plot = profile["plot"] as? String {
            movie.plot = plot
        }

        applyPoster(to: movie)

        return movie
    }

    private func applyPoster(to movie: Movie) {
        let publicDirectory = URL(fileURLWithPath: "\(DirectoryConfiguration.detect().publicDirectory)/Posters")
        let posterPaths = try? FileManager().contentsOfDirectory(at: publicDirectory, includingPropertiesForKeys: nil)

        let originalTitle = movie.originalTitle?.replacingOccurrences(of: ":", with: "").lowercased()

        if let posterPath = posterPaths?.first(where: { $0.fileNameWithoutExtension == originalTitle }) {
            let url = Config.postersURL?.appendingPathComponent(posterPath.fileNameWithExtension)
            movie.poster = url?.absoluteString
        } else {
            movie.poster = nil
        }
    }

    private func loadProfiles() -> [String: AnyObject]? {
        let publicDirectory = DirectoryConfiguration.detect().publicDirectory
        let url = URL(fileURLWithPath: publicDirectory + "Profiles.plist")
        guard let data = try? Data(contentsOf: url) else { return nil }

        return try? PropertyListSerialization.propertyList(from: data,
                                                           options: .mutableContainers,
                                                           format: .none) as? [String: AnyObject]
    }

    // Replaces `Movie`s `originalTitle` property with new value from `OriginalTitles.plist` file.
    func customizeOriginalTitle(for movie: Movie) -> Movie {
        guard let originalTitles = readOriginalTitlesPlist() else { fatalError("Could not open `OriginalTitles.plist`!") }

        for (key, value) in originalTitles {
            movie.originalTitle = movie.originalTitle?.replacingOccurrences(of: key, with: value)
        }

        return movie
    }

    private func readOriginalTitlesPlist() -> [String: String]? {
        let publicDirectory = DirectoryConfiguration.detect().publicDirectory
        let url = URL(fileURLWithPath: publicDirectory + "OriginalTitles.plist")
        guard let data = try? Data(contentsOf: url) else { return nil }

        return try? PropertyListSerialization.propertyList(from: data,
                                                           options: .mutableContainers,
                                                           format: .none) as? [String: String]
    }
}

extension URL {
    fileprivate var fileNameWithoutExtension: String {
        self.deletingPathExtension().lastPathComponent.lowercased()
    }

    fileprivate var fileNameWithExtension: String {
        self.lastPathComponent.lowercased()
    }
}
