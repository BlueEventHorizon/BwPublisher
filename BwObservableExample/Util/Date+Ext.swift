//
//  Date+Ext.swift
//  BwFramework
//
//  Created by Katsuhiko Terada on 2017/08/18.
//  Copyright (c) 2017 Katsuhiko Terada. All rights reserved.
//

import Foundation

// =============================================================================
// MARK: - Date/Time
// =============================================================================

public enum FormatterType: String {
    case full = "yyyy-MM-dd'T'HH:mm:ssZ"
    case std = "yyyy-MM-dd HH:mm:ss"
}

// =============================================================================
// MARK: - DateFormatter
// =============================================================================

extension DateFormatter {
    // 現在タイムゾーンの標準フォーマッタ
    public static let standard: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
}

// =============================================================================
// MARK: - Calendar
// =============================================================================

extension Calendar {
    public static let standard: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.locale   = .current
        return calendar
    }()
}

// =============================================================================
// MARK: - DateComponents
// =============================================================================

extension DateComponents {
    public init(year: Int = 0, month: Int = 0, day: Int = 0, hour: Int = 0, minute: Int = 0, second: Int = 0) {
        self.init(calendar: Calendar(identifier: .gregorian),
                  timeZone: TimeZone.current,
                  year: year,
                  month: month,
                  day: day,
                  hour: hour,
                  minute: minute,
                  second: second)
    }
}

// =============================================================================
// MARK: - 文字列 <-> Date
// =============================================================================

extension Date {
    // Date → String
    public func string(dateFormat: String) -> String {
        let formatter = DateFormatter.standard
        formatter.dateFormat = dateFormat
        return formatter.string(from: self)
    }

    // String → Date
    public init?(dateString: String, dateFormat: String) {
        let formatter = DateFormatter.standard
        formatter.dateFormat = dateFormat
        guard let date = formatter.date(from: dateString) else { return nil }
        self = date
    }
}
