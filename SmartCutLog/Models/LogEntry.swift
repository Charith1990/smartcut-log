//
//  LogEntry.swift
//  SmartCutLog
//
//  The 2026 Apple AI Stack · Part 2 — The Invisible Intelligence
//  App Intents × Foundation Models
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import Foundation
import SwiftData

// MARK: - Stored record
//
// CapturedItem (the @Generable struct) only lives for the moment the model
// produces it. LogEntry is the saved version. We write it to disk so notes stay
// after the app closes and show up in the list.
//
// @Model is SwiftData's macro. It turns a class into a stored entity: SwiftData
// makes the storage, watches the properties, and saves changes for us. The macro
// needs a class (not a struct), and we mark it final.

@Model
final class LogEntry {

    /// The original sentence the user typed or said. We keep it so the user can
    /// see their own words next to the model's version.
    var rawText: String

    /// The short title the model wrote.
    var title: String

    // We store category and priority as their raw strings ("task", "high"), not
    // as the enums. SwiftData can store enums, but plain strings are simpler and
    // easier to filter later with #Predicate. The typed category/priority
    // accessors below convert them back to enums for the rest of the app.
    var categoryRaw: String
    var priorityRaw: String

    /// A real Date, already parsed from the model's "yyyy-MM-dd" string in
    /// CaptureService. nil if the note had no date.
    var dueDate: Date?

    /// Amount for expenses. nil for everything else.
    var amount: Double?

    /// When we saved this. Used to sort the list newest first.
    var createdAt: Date

    init(
        rawText: String,
        title: String,
        category: ItemCategory,
        priority: ItemPriority,
        dueDate: Date? = nil,
        amount: Double? = nil,
        createdAt: Date = .now
    ) {
        self.rawText = rawText
        self.title = title
        self.categoryRaw = category.rawValue
        self.priorityRaw = priority.rawValue
        self.dueDate = dueDate
        self.amount = amount
        self.createdAt = createdAt
    }
}

// MARK: - Typed accessors
//
// Turn the stored strings back into enums for the UI. The ?? fallback means a
// bad stored value can never crash the app.
extension LogEntry {
    var category: ItemCategory { ItemCategory(rawValue: categoryRaw) ?? .idea }
    var priority: ItemPriority { ItemPriority(rawValue: priorityRaw) ?? .normal }
}
