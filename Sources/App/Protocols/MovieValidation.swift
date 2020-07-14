//
//  MovieValidation.swift
//  
//
//  Created by Marius on 2020-07-13.
//

import Vapor

protocol MovieValidation: AnyObject {
    var validationReport: String { get set }

    func validate(_ movie: Movie) -> Movie?
}

extension MovieValidation {
    func validate(_ movie: Movie) -> Movie? {
        var didFailValidation = false

        guard let originalTitle = movie.originalTitle else {
            appendReport(with: "`originalTitle` is nil!")
            return nil
        }

        if movie.title == nil {
            didFailValidation = true
            appendReport(with: "\(originalTitle) `title` is nil!")
        }

        if movie.year == nil {
            didFailValidation = true
            appendReport(with: "\(originalTitle) `year` is nil!")
        }

        if movie.duration == nil {
            didFailValidation = true
            appendReport(with: "\(originalTitle) `duration` is nil!")
        }

        if movie.ageRating == nil {
            didFailValidation = true
            appendReport(with: "\(originalTitle) `ageRating` is nil!")
        }

        if movie.genres == nil {
            didFailValidation = true
            appendReport(with: "\(originalTitle) `genres` is nil!")
        }

        if movie.plot == nil {
            didFailValidation = true
            appendReport(with: "\(originalTitle) `plot` is nil!")
        }

        if movie.poster == nil {
            didFailValidation = true
            appendReport(with: "\(originalTitle) `poster` is nil!")
        }

        if movie.showings.isEmpty {
            didFailValidation = true
            appendReport(with: "\(originalTitle) `showings` is empty!")
        }

        if didFailValidation {
            appendReport(with: "")
            return nil
        } else {
            return movie
        }
    }

    private func appendReport(with message: String) {
        validationReport.append(contentsOf: message + "\n")
    }
}
