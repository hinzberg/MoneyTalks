//
//  BackupCoordinator.swift
//  MoneyTalks
//

import Foundation
import Observation
import SwiftUI
import UniformTypeIdentifiers

/// Wraps the encoded backup so it can be written by SwiftUI's fileExporter.
struct BackupFileDocument: FileDocument {

    static var readableContentTypes: [UTType] { [.moneyTalksBackup] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw BackupExporter.ExportError.encodingFailed("The file contains no data.")
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

@Observable
@MainActor
final class BackupCoordinator {

    var isExporting = false
    var isImporting = false
    var errorMessage: String?
    var resultMessage: String?

    private var pendingExportData: Data?

    // MARK: - Export

    /// Encodes the current data and opens the save panel.
    func prepareExport(walletRepository: WalletRepository, revenueRepository: RevenueRepository) {
        let document = BackupDocument(
            exportDate: Date(),
            wallets: walletRepository.wallets.map(WalletBackupEntry.init),
            revenues: revenueRepository.revenues.map(RevenueBackupEntry.init))
        do {
            pendingExportData = try BackupExporter().data(from: document)
            errorMessage = nil
            isExporting = true
        } catch {
            pendingExportData = nil
            resultMessage = nil
            errorMessage = error.localizedDescription
        }
    }

    var exportDocument: BackupFileDocument {
        BackupFileDocument(data: pendingExportData ?? Data())
    }

    var exportFileName: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "MoneyTalks Backup \(formatter.string(from: Date()))"
    }

    func exportFinished(_ result: Result<URL, Error>) {
        pendingExportData = nil
        switch result {
        case .success(let url):
            errorMessage = nil
            resultMessage = "The backup was exported to '\(url.lastPathComponent)'."
        case .failure(let error):
            if Self.isCancellation(error) { return }
            resultMessage = nil
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Import

    /// Restores wallets first, then revenues, merging with the stored data:
    /// items whose id is already present are skipped.
    func importBackup(from url: URL,
                      walletRepository: WalletRepository,
                      revenueRepository: RevenueRepository) {
        do {
            let document = try BackupImporter().document(from: url)

            let walletsAdded = walletRepository.add(
                contentsOf: document.wallets.map { $0.makeWallet() })

            var walletByID: [UUID: Wallet] = [:]
            for wallet in walletRepository.wallets {
                walletByID[wallet.id] = wallet
            }

            var revenues: [Revenue] = []
            for entry in document.revenues
            where !revenueRepository.revenues.contains(where: { $0.id == entry.id }) {
                let revenue = entry.makeRevenue()
                revenue.wallet = entry.walletID.flatMap { walletByID[$0] }
                if revenue.wallet == nil {
                    revenue.walletConfirmed = false
                }
                revenues.append(revenue)
            }
            let revenuesAdded = revenueRepository.add(contentsOf: revenues)
            let skippedCount = document.revenues.count - revenuesAdded

            errorMessage = nil
            resultMessage = Self.importResultMessage(walletsAdded: walletsAdded,
                                                     revenuesAdded: revenuesAdded,
                                                     skippedCount: skippedCount)
        } catch {
            resultMessage = nil
            errorMessage = error.localizedDescription
        }
    }

    func importFinished(_ result: Result<[URL], Error>,
                        walletRepository: WalletRepository,
                        revenueRepository: RevenueRepository) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importBackup(from: url,
                         walletRepository: walletRepository,
                         revenueRepository: revenueRepository)
        case .failure(let error):
            if Self.isCancellation(error) { return }
            resultMessage = nil
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private static func importResultMessage(walletsAdded: Int, revenuesAdded: Int, skippedCount: Int) -> String {
        var message = "\(walletsAdded) \(walletsAdded == 1 ? "wallet" : "wallets") and "
        message += "\(revenuesAdded) \(revenuesAdded == 1 ? "revenue" : "revenues") imported."
        if skippedCount > 0 {
            message += " \(skippedCount) "
            message += skippedCount == 1 ? "revenue was skipped, because it was already imported."
                                         : "revenues were skipped, because they were already imported."
        }
        return message
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? CocoaError)?.code == .userCancelled
    }
}
