//
//  RevenueCSVImporter.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import Foundation

struct RevenueCSVImporter: Sendable {

    enum ImportError: LocalizedError {
        case unreadableFile(name: String)
        case emptyFile
        case missingColumns([String])
        case missingValue(line: Int, column: String)
        case invalidValue(line: Int, column: String, value: String)

        var errorDescription: String? {
            switch self {
            case .unreadableFile(let name):
                return "The file '\(name)' could not be read."
            case .emptyFile:
                return "The selected file does not contain any data."
            case .missingColumns(let columns):
                return "The file is missing the following columns: \(columns.joined(separator: ", "))."
            case .missingValue(let line, let column):
                return "Row \(line) does not contain a value for the column '\(column)'."
            case .invalidValue(let line, let column, let value):
                return "Row \(line) contains the invalid value '\(value)' in the column '\(column)'."
            }
        }
    }

    private enum Column: String, CaseIterable {
        case accountNumber = "Auftragskonto"
        case bookingDate = "Buchungstag"
        case valueDate = "Valutadatum"
        case bookingText = "Buchungstext"
        case purpose = "Verwendungszweck"
        case creditorIdentifier = "Glaeubiger ID"
        case mandateReference = "Mandatsreferenz"
        case endToEndReference = "Kundenreferenz (End-to-End)"
        case collectorReference = "Sammlerreferenz"
        case originalDirectDebitAmount = "Lastschrift Ursprungsbetrag"
        case directDebitReturnCosts = "Auslagenersatz Ruecklastschrift"
        case beneficiaryOrPayer = "Beguenstigter/Zahlungspflichtiger"
        case iban = "Kontonummer/IBAN"
        case bic = "BIC (SWIFT-Code)"
        case amount = "Betrag"
        case currency = "Waehrung"
        case info = "Info"
        case category = "Kategorie"
    }

    private let delimiter: Character

    init(delimiter: Character = ";") {
        self.delimiter = delimiter
    }

    func revenues(contentsOf url: URL) throws -> [Revenue] {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.unreadableFile(name: url.lastPathComponent)
        }

        guard let text = Self.text(from: data) else {
            throw ImportError.unreadableFile(name: url.lastPathComponent)
        }

        let rows = Self.rows(in: text, delimiter: delimiter)

        guard let headerRowIndex = rows.firstIndex(where: { $0.contains { !$0.isEmpty } }) else {
            throw ImportError.emptyFile
        }

        var indexByColumn: [Column: Int] = [:]
        for (index, field) in rows[headerRowIndex].enumerated() {
            if let column = Column(rawValue: field) {
                indexByColumn[column] = index
            }
        }

        let missingColumns = Column.allCases.filter { indexByColumn[$0] == nil }.map(\.rawValue)
        guard missingColumns.isEmpty else {
            throw ImportError.missingColumns(missingColumns)
        }

        var revenues: [Revenue] = []
        for rowIndex in rows.index(after: headerRowIndex)..<rows.endIndex {
            let row = rows[rowIndex]
            guard row.contains(where: { !$0.isEmpty }) else { continue }
            revenues.append(try revenue(from: row, indexByColumn: indexByColumn, line: rowIndex + 1))
        }
        return revenues
    }

    private func revenue(from row: [String], indexByColumn: [Column: Int], line: Int) throws -> Revenue {
        func value(_ column: Column) throws -> String {
            guard let index = indexByColumn[column], index < row.count else {
                throw ImportError.missingValue(line: line, column: column.rawValue)
            }
            return row[index]
        }

        func optionalValue(_ column: Column) -> String? {
            guard let index = indexByColumn[column], index < row.count else { return nil }
            return row[index].isEmpty ? nil : row[index]
        }

        func amount(_ column: Column) throws -> Decimal? {
            guard let text = optionalValue(column) else { return nil }
            guard let amount = Self.amount(from: text) else {
                throw ImportError.invalidValue(line: line, column: column.rawValue, value: text)
            }
            return amount
        }

        func date(_ column: Column) throws -> Date {
            let text = try value(column)
            guard let date = Self.date(from: text) else {
                throw ImportError.invalidValue(line: line, column: column.rawValue, value: text)
            }
            return date
        }

        return Revenue(
            accountNumber: try value(.accountNumber),
            bookingDate: try date(.bookingDate),
            valueDate: try date(.valueDate),
            bookingText: try value(.bookingText),
            purpose: try value(.purpose),
            creditorIdentifier: optionalValue(.creditorIdentifier),
            mandateReference: optionalValue(.mandateReference),
            endToEndReference: optionalValue(.endToEndReference),
            collectorReference: optionalValue(.collectorReference),
            originalDirectDebitAmount: try amount(.originalDirectDebitAmount),
            directDebitReturnCosts: try amount(.directDebitReturnCosts),
            beneficiaryOrPayer: try value(.beneficiaryOrPayer),
            iban: try value(.iban),
            bic: try value(.bic),
            amount: try amount(.amount) ?? 0,
            currency: try value(.currency),
            info: try value(.info),
            category: optionalValue(.category),
            note: "",
            categorizedPurpose: ""
        )
    }

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()

    private static func text(from data: Data) -> String? {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            return nil
        }
        return text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
    }

    private static func rows(in text: String, delimiter: Character) -> [[String]] {
        let normalizedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var rows: [[String]] = []
        var fields: [String] = []
        var field = ""
        var isInsideQuotes = false
        var index = normalizedText.startIndex

        while index < normalizedText.endIndex {
            let character = normalizedText[index]
            if isInsideQuotes {
                if character == "\"" {
                    let nextIndex = normalizedText.index(after: index)
                    if nextIndex < normalizedText.endIndex, normalizedText[nextIndex] == "\"" {
                        field.append("\"")
                        index = nextIndex
                    } else {
                        isInsideQuotes = false
                    }
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"":
                    isInsideQuotes = true
                case delimiter:
                    fields.append(field)
                    field = ""
                case "\n":
                    fields.append(field)
                    rows.append(fields)
                    fields = []
                    field = ""
                default:
                    field.append(character)
                }
            }
            index = normalizedText.index(after: index)
        }

        if !field.isEmpty || !fields.isEmpty {
            fields.append(field)
            rows.append(fields)
        }
        return rows.map { row in
            row.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
    }

    private static func amount(from string: String) -> Decimal? {
        let normalized = string.contains(",")
            ? string.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            : string
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func date(from string: String) -> Date? {
        let parts = string.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = Int(parts[1]),
              let rawYear = Int(parts[2]) else { return nil }

        let year: Int
        if rawYear < 100 {
            year = rawYear < 70 ? 2000 + rawYear : 1900 + rawYear
        } else {
            year = rawYear
        }

        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        return calendar.date(from: dateComponents)
    }
}
