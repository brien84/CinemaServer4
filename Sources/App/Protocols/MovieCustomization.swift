//
//  MovieCustomization.swift
//  
//
//  Created by Marius on 2020-07-08.
//

import Vapor

protocol MovieCustomization {
    var cinemaIdentifier: String { get }

    func customizeOriginalTitle(for movie: Movie) -> Movie
}

extension MovieCustomization {
    // Modifies `Movie`s `originalTitle` property by replacing provided values
    // with new values from `OriginalTitles.plist` file.
    func customizeOriginalTitle(for movie: Movie) -> Movie {
        guard let originalTitles = readOriginalTitlesPlist() else {
            print("Could not open `OriginalTitles.plist`!")
            return movie
        }

        for (key, value) in originalTitles {
            movie.originalTitle = movie.originalTitle?.replacingOccurrences(of: key, with: value)
        }

        return movie
    }

    private func readOriginalTitlesPlist() -> [String: String]? {
        let publicDirectory = DirectoryConfiguration.detect().publicDirectory
        let url = URL(fileURLWithPath: publicDirectory + "OriginalTitles.plist")
        guard let data = try? Data(contentsOf: url) else { return nil }

        let rootDictionary = try? PropertyListSerialization.propertyList(from: data,
                                                                         options: .mutableContainers,
                                                                         format: .none) as? [String: AnyObject]

        return rootDictionary?[cinemaIdentifier] as? [String: String]
    }
}
