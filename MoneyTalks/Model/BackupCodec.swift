//
//  BackupCodec.swift
//  MoneyTalks
//

import Foundation

/// Encodes a BackupDocument as pretty-printed JSON.
struct BackupExporter: Sendable {

    enum ExportError: LocalizedError {
        case encodingFailed(String)

        var errorDescription: String? {
            switch self {
            case .encodingFailed(let reason):
                return "The backup could not be created: \(reason)"
            }
        }
    }

    func data(from document: BackupDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            return try encoder.encode(document)
        } catch {
            throw ExportError.encodingFailed(error.localizedDescription)
        }
    }
}

/// Decodes a BackupDocument from a backup file.
struct BackupImporter: Sendable {

    enum ImportError: LocalizedError, Equatable {
        case unreadableFile(name: String)
        case notABackup(name: String)
        case unsupportedSchemaVersion(Int)
        case emptyBackup

        var errorDescription: String? {
            switch self {
            case .unreadableFile(let name):
                return "The file '\(name)' could not be read."
            case .notABackup(let name):
                return "The file '\(name)' is not a valid MoneyTalks backup."
            case .unsupportedSchemaVersion(let version):
                return "The backup uses format version \(version), which is not supported by this version of MoneyTalks."
            case .emptyBackup:
                return "The selected backup does not contain any wallets or revenues."
            }
        }
    }

    func document(from url: URL) throws -> BackupDocument {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.unreadableFile(name: url.lastPathComponent)
        }
        return try document(from: data, name: url.lastPathComponent)
    }

    func document(from data: Data) throws -> BackupDocument {
        return try document(from: data, name: "backup")
    }

    private func document(from data: Data, name: String) throws -> BackupDocument {
        let document: BackupDocument
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            document = try decoder.decode(BackupDocument.self, from: data)
        } catch {
            throw ImportError.notABackup(name: name)
        }

        guard document.schemaVersion <= BackupDocument.currentSchemaVersion else {
            throw ImportError.unsupportedSchemaVersion(document.schemaVersion)
        }
        guard !document.wallets.isEmpty || !document.revenues.isEmpty else {
            throw ImportError.emptyBackup
        }
        return document
    }
}
