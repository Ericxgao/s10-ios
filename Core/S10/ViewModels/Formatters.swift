//
//  Formatters.swift
//  Taylr
//
//  Created by Tony Xiao on 4/17/15.
//  Copyright (c) 2015 S10 Inc. All rights reserved.
//

import Foundation
import FormatterKit
import DateTools

public struct Formatters {
    private static let height : NSLengthFormatter = {
        let formatter = NSLengthFormatter()
        formatter.forPersonHeightUse = true
        formatter.unitStyle = .Short
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()
    private static let timeInterval: TTTTimeIntervalFormatter = {
        let formatter = TTTTimeIntervalFormatter()
        formatter.usesIdiomaticDeicticExpressions = true
        formatter.usesAbbreviatedCalendarUnits = true
        return formatter
    }()
    
    public static func formatHeight(heightInCm: Int) -> String {
        return height.stringFromMeters(Double(heightInCm) / 100)
    }
    
    // TODO: Move formatting into localizable
    public static func formatRelativeDate(date: NSDate) -> String {
        let interval = NSDate().timeIntervalSinceDate(date)
        let secondsPerDay: Double = 24 * 60 * 60
        
        if interval > secondsPerDay * 365 {
            return date.formattedDateWithFormat("MMM d, yyyy") // 13 Jun, 2015
        } else if interval > secondsPerDay * 7 {
            return date.formattedDateWithFormat("MMM d") // 13 Jun
        } else if interval > secondsPerDay * 2 {
            return date.formattedDateWithFormat("EEEE h:mma") // Saturday 1:05PM
        } else if interval > secondsPerDay {
            let timeText = date.formattedDateWithFormat("h:mma")
            return "Yesterday \(timeText)"
        } else {
            return timeInterval.stringForTimeIntervalFromDate(NSDate(), toDate: date)
        }
    }
    
}