//
//  ChromeCSVImporter.swift
//  SwiftFastPass
//

import Foundation

struct ChromeCSVEntry {
    let name: String
    let url: String?
    let username: String?
    let password: String?
    let note: String?
}

struct ChromeCSVImportResult {
    let entries: [ChromeCSVEntry]
    let failedRowCount: Int
}

enum ChromeCSVImportError: LocalizedError {
    case invalidEncoding
    case missingRequiredColumns
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return NSLocalizedString("Unable to read the file. Please export again and retry.", comment: "")
        case .missingRequiredColumns:
            return NSLocalizedString("The CSV file is missing required columns like name, URL, username, or password.", comment: "")
        case .emptyContent:
            return NSLocalizedString("No passwords were found in the CSV file.", comment: "")
        }
    }
}

/// Minimal CSV parser for Chrome password export (`name,url,username,password[,note]`).
final class ChromeCSVImporter {
    private struct HeaderMap {
        let name: Int
        let url: Int?
        let username: Int?
        let password: Int?
        let note: Int?
    }

    func parse(data: Data) throws -> ChromeCSVImportResult {
        guard let content = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .utf16LittleEndian)
            ?? String(data: data, encoding: .utf16BigEndian)
        else {
            throw ChromeCSVImportError.invalidEncoding
        }

        let rows = parseRows(in: content)
        guard let headerRow = rows.first else {
            throw ChromeCSVImportError.emptyContent
        }

        let header = try headerMap(for: headerRow)
        let payloadRows = rows.dropFirst()
        guard !payloadRows.isEmpty else {
            throw ChromeCSVImportError.emptyContent
        }

        var entries: [ChromeCSVEntry] = []
        var failedRows = 0

        for row in payloadRows {
            if let entry = mapRow(row, header: header) {
                entries.append(entry)
            } else {
                failedRows += 1
            }
        }

        guard !entries.isEmpty else {
            throw ChromeCSVImportError.emptyContent
        }

        return ChromeCSVImportResult(entries: entries, failedRowCount: failedRows)
    }

    private func headerMap(for headers: [String]) throws -> HeaderMap {
        let trimmed = headers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        func index(of options: [String]) -> Int? {
            for option in options {
                if let idx = trimmed.firstIndex(of: option) {
                    return idx
                }
            }
            return nil
        }

        let nameIndex = index(of: ["name", "title"]) ?? index(of: ["\u{feff}name"])
        let urlIndex = index(of: ["url", "origin", "website"])
        let usernameIndex = index(of: ["username", "user", "login"])
        let passwordIndex = index(of: ["password", "pass"])
        let noteIndex = index(of: ["note", "notes", "comment"])

        guard let nameIdx = nameIndex else {
            throw ChromeCSVImportError.missingRequiredColumns
        }
        guard urlIndex != nil || usernameIndex != nil || passwordIndex != nil else {
            throw ChromeCSVImportError.missingRequiredColumns
        }

        return HeaderMap(name: nameIdx,
                         url: urlIndex,
                         username: usernameIndex,
                         password: passwordIndex,
                         note: noteIndex)
    }

    private func mapRow(_ row: [String], header: HeaderMap) -> ChromeCSVEntry? {
        func value(at index: Int?) -> String? {
            guard let index,
                  index >= 0,
                  index < row.count
            else {
                return nil
            }
            let trimmed = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        let name = value(at: header.name) ?? ""
        let url = value(at: header.url)
        let username = value(at: header.username)
        let password = value(at: header.password)
        let note = value(at: header.note)

        // Skip rows that have no meaningful content.
        if name.isEmpty && username == nil && password == nil && url == nil {
            return nil
        }

        return ChromeCSVEntry(name: name, url: url, username: username, password: password, note: note)
    }

    // Simple CSV reader that respects quotes and escaped quotes.
    private func parseRows(in content: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false

        var scalars = content.unicodeScalars
        var index = scalars.startIndex

        func endField() {
            currentRow.append(currentField)
            currentField = ""
        }

        func endRow() {
            endField()
            let isEmptyRow = currentRow.allSatisfy { $0.isEmpty }
            if !isEmptyRow {
                rows.append(currentRow)
            }
            currentRow = []
        }

        while index < scalars.endIndex {
            let scalar = scalars[index]

            if scalar == "\"" {
                let nextIndex = scalars.index(after: index)
                if inQuotes, nextIndex < scalars.endIndex, scalars[nextIndex] == "\"" {
                    currentField.unicodeScalars.append("\"")
                    index = nextIndex
                } else {
                    inQuotes.toggle()
                }
            } else if scalar == "," && !inQuotes {
                endField()
            } else if (scalar == "\n" || scalar == "\r") && !inQuotes {
                // Handle \r\n by peeking ahead.
                if scalar == "\r" {
                    let nextIndex = scalars.index(after: index)
                    if nextIndex < scalars.endIndex, scalars[nextIndex] == "\n" {
                        index = nextIndex
                    }
                }
                endRow()
            } else {
                currentField.unicodeScalars.append(scalar)
            }

            index = scalars.index(after: index)
        }

        // Flush final field/row if needed.
        if !inQuotes {
            if !currentField.isEmpty || !currentRow.isEmpty {
                endRow()
            }
        }

        return rows
    }
}
