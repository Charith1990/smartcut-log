//
//  ContentView.swift
//  SmartCutLog
//
//  The 2026 Apple AI Stack · Part 2 — The Invisible Intelligence
//  App Intents × Foundation Models
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import SwiftUI
import SwiftData

// MARK: - Main screen
//
// A list of saved notes, plus a capture bar at the bottom to add one from inside
// the app (useful for testing without Siri). It runs the same steps the intent
// uses: CaptureService.extract, makeLogEntry, then insert and save.

struct ContentView: View {

    // The shared database context, injected in SmartCutLogApp with
    // .modelContainer(...). We insert and save through it.
    @Environment(\.modelContext) private var modelContext

    // @Query loads LogEntry rows and refreshes when they change, including when
    // the background Siri intent writes to the same store.
    @Query(sort: \LogEntry.createdAt, order: .reverse) private var entries: [LogEntry]

    @State private var draft = ""
    @State private var isCapturing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No captures yet",
                        systemImage: "square.and.pencil",
                        description: Text("Type a note below, or say \u{201C}Hey Siri, log a note in SmartCut Log.\u{201D}")
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            CaptureRowView(entry: entry)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("SmartCut Log")
            .safeAreaInset(edge: .bottom) { captureBar }
            .alert("Couldn\u{2019}t capture", isPresented: showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // The bottom input row.
    private var captureBar: some View {
        HStack(spacing: 12) {
            TextField("Log something\u{2026}", text: $draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)
                .disabled(isCapturing)
                .onSubmit(capture)

            Button(action: capture) {
                if isCapturing {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
            }
            .disabled(trimmedDraft.isEmpty || isCapturing)
        }
        .padding()
        .background(.bar)
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Shows the alert whenever errorMessage is set.
    private var showError: Binding<Bool> {
        Binding { errorMessage != nil } set: { if !$0 { errorMessage = nil } }
    }

    // Runs the model, then saves the result.
    private func capture() {
        let text = trimmedDraft
        guard !text.isEmpty else { return }
        isCapturing = true

        // The Task runs on the view's main actor, so the SwiftData writes after
        // await stay on the main actor. No concurrency problems.
        Task {
            do {
                let item = try await CaptureService.shared.extract(from: text)
                let entry = CaptureService.shared.makeLogEntry(from: item, rawText: text)
                modelContext.insert(entry)
                try modelContext.save()
                draft = ""
            } catch {
                errorMessage = error.localizedDescription
            }
            isCapturing = false
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}

// MARK: - One row
//
// Shows a single note: the title, a colored category badge, and any details the
// model found (due date, amount, high priority). The original text sits under
// it, so you can compare what you said with what the model made of it.

struct CaptureRowView: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.title).font(.headline)
                Spacer()
                categoryBadge
            }

            HStack(spacing: 12) {
                if let due = entry.dueDate {
                    Label(due.formatted(date: .abbreviated, time: .omitted),
                          systemImage: "calendar")
                }
                if let amount = entry.amount {
                    Label(amount.formatted(.currency(code: currencyCode)),
                          systemImage: "dollarsign.circle")
                }
                if entry.priority == .high {
                    Label("High", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(entry.rawText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }

    private var categoryBadge: some View {
        Text(entry.category.rawValue.capitalized)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(categoryColor.opacity(0.15), in: Capsule())
            .foregroundStyle(categoryColor)
    }

    private var categoryColor: Color {
        switch entry.category {
        case .task: .blue
        case .expense: .green
        case .idea: .purple
        case .event: .orange
        }
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
}

#Preview {
    ContentView()
        .modelContainer(for: LogEntry.self, inMemory: true)
}
