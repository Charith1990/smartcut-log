//
//  CapturedItem.swift
//  SmartCutLog
//
//  The 2026 Apple AI Stack · Part 2 — The Invisible Intelligence
//  App Intents × Foundation Models
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import Foundation
import FoundationModels

// MARK: - Model output type
//
// This is the shape we want the model to return. We mark it @Generable so the
// Foundation Models framework can use it as the output schema.
//
// When we call session.respond(to: rawText, generating: CapturedItem.self), the
// framework makes the model fill in this struct directly. We get a real Swift
// value back with the right fields and types, so we do not parse any JSON.

/// The structured result we want the model to pull out of one raw note.
@Generable
struct CapturedItem {

    /// Category of the note. @Guide(.anyOf:) limits the model to these exact
    /// values, so it cannot make up a new category. We keep it as a String here
    /// (not the ItemCategory enum) because the @Generable macro does not handle
    /// enums well in this beta. CaptureService turns the string back into
    /// ItemCategory later.
    @Guide(.anyOf(["task", "expense", "idea", "event"]))
    var category: String

    /// A short, clean title for the note. The @Guide text tells the model how to
    /// write it.
    @Guide(description: "A concise title of 3 to 7 words, no trailing punctuation.")
    var title: String

    /// Due date as text in yyyy-MM-dd form. We use a String, not a Date, to keep
    /// the schema simple. CaptureService parses it into a real Date. If the note
    /// has no date, this stays nil.
    @Guide(description: "Due date as yyyy-MM-dd if the text mentions a day or time; otherwise omit.")
    var dueDate: String?

    /// Priority. Also limited to a fixed set of values with @Guide(.anyOf:).
    @Guide(.anyOf(["low", "normal", "high"]))
    var priority: String

    /// Money amount, only used for expenses. Optional, so other notes leave it nil.
    @Guide(description: "The numeric amount if this is an expense, e.g. 42.50; otherwise omit.")
    var amount: Double?
}

// MARK: - App enums (plain Swift, not @Generable)
//
// These are normal enums we use for storage and for the UI. The model does not
// use them directly. It returns strings (limited by @Guide above), and
// CaptureService converts those strings into these enums with
// ItemCategory(rawValue:).
//
// ": String" gives each case a stored value we save in SwiftData. CaseIterable
// lets the UI list all the cases.

/// The kind of note.
enum ItemCategory: String, Codable, CaseIterable {
    case task
    case expense
    case idea
    case event
}

/// How urgent the note is.
enum ItemPriority: String, Codable, CaseIterable {
    case low
    case normal
    case high
}
