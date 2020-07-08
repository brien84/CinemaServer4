//
//  Extensions.swift
//  
//
//  Created by Marius on 2020-07-08.
//

import Foundation

extension String {
    func convertToDate() -> Date? {
        let dateFormatter = DateFormatter()

        guard let timeZone = TimeZone(identifier: "Europe/Vilnius") else { fatalError("TimeZone not found!") }
        dateFormatter.timeZone = timeZone

        // ForumCinemas format: 19.09.2019 11:00
        dateFormatter.dateFormat = "dd'.'MM'.'yyyy' 'HH':'mm"
        if let date = dateFormatter.date(from: self) {
            return date
        }

        return nil
    }
}
