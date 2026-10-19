//
//  BackupTests.swift
//  MoneyTalksTests
//

import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import MoneyTalks

@MainActor
struct BackupTests {

    private let container: ModelContainer
    private let revenueRepository: RevenueRepository
    private let walletRepository: WalletRepository

    init() throws {
        container = try ModelContainer(
            for: Revenue.self, Wallet.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        revenueRepository = RevenueRepository(modelContext: container.mainContext)
        walletRepository = WalletRepository(modelContext: container.mainContext)
    }

    // MARK: - Round Trip

    @Test func exportAndImportRoundTripPreservesAllValues() throws {
        let wallet = makeWallet()
        let revenue = makeRevenue(amount: "12345678901234.56")
        revenue.wallet = wallet
        revenue.walletConfirmed = true

        let exportDate = Date(timeIntervalSince1970: 1_760_000_000)
        let document = BackupDocument(
            exportDate: exportDate,
            wallets: [WalletBackupEntry(wallet)],
            revenues: [RevenueBackupEntry(revenue)])

        let data = try BackupExporter().data(from: document)
        let decoded = try BackupImporter().document(from: data)

        #expect(decoded == document)
    }

    @Test func importIntoEmptyRepositoriesRestoresWalletAndWalletLink() throws {
        let wallet = makeWallet()
        let revenue = makeRevenue()
        revenue.wallet = wallet
        revenue.walletConfirmed = true
        let data = try BackupExporter().data(
            from: BackupDocument(wallets: [WalletBackupEntry(wallet)],
                                 revenues: [RevenueBackupEntry(revenue)]))

        let url = try writeTemporaryFile(data)
        BackupCoordinator().importBackup(from: url,
                                             walletRepository: walletRepository,
                                             revenueRepository: revenueRepository)

        #expect(walletRepository.wallets.count == 1)
        #expect(walletRepository.wallets.first?.colorHex == wallet.colorHex)
        #expect(revenueRepository.revenues.count == 1)

        let restored = try #require(revenueRepository.revenues.first)
        #expect(restored.id == revenue.id)
        #expect(restored.amount == revenue.amount)
        #expect(restored.bookingDate == revenue.bookingDate)
        #expect(restored.note == revenue.note)
        #expect(restored.wallet?.id == wallet.id)
        #expect(restored.walletConfirmed == true)
        #expect(container.mainContext.hasChanges == false)
    }

    @Test func importKeepsExistingWalletWhenIdAlreadyStored() throws {
        let stored = makeWallet(name: "Girokonto")
        walletRepository.add(stored)

        let renamed = makeWallet(id: stored.id, name: "Andere Bank")
        let data = try BackupExporter().data(from: BackupDocument(wallets: [WalletBackupEntry(renamed)]))
        let url = try writeTemporaryFile(data)

        BackupCoordinator().importBackup(from: url,
                                             walletRepository: walletRepository,
                                             revenueRepository: revenueRepository)

        #expect(walletRepository.wallets.count == 1)
        #expect(walletRepository.wallets.first?.name == "Girokonto")
    }

    // MARK: - Merging

    @Test func importingSameBackupTwiceSkipsDuplicates() throws {
        let wallet = makeWallet()
        let revenue = makeRevenue()
        revenue.wallet = wallet
        let data = try BackupExporter().data(
            from: BackupDocument(wallets: [WalletBackupEntry(wallet)],
                                 revenues: [RevenueBackupEntry(revenue)]))
        let url = try writeTemporaryFile(data)

        let coordinator = BackupCoordinator()
        coordinator.importBackup(from: url,
                                 walletRepository: walletRepository,
                                 revenueRepository: revenueRepository)
        #expect(coordinator.resultMessage?.contains("1 revenue imported") == true)

        coordinator.importBackup(from: url,
                                 walletRepository: walletRepository,
                                 revenueRepository: revenueRepository)

        #expect(walletRepository.wallets.count == 1)
        #expect(revenueRepository.revenues.count == 1)
        #expect(coordinator.resultMessage?.contains("skipped") == true)
        #expect(coordinator.errorMessage == nil)
        #expect(container.mainContext.hasChanges == false)
    }

    @Test func importWithUnknownWalletIDClearsConfirmation() throws {
        let entry = RevenueBackupEntry(makeRevenue())
        var broken = entry
        broken.walletID = UUID()
        broken.walletConfirmed = true
        let data = try BackupExporter().data(from: BackupDocument(revenues: [broken]))
        let url = try writeTemporaryFile(data)

        BackupCoordinator().importBackup(from: url,
                                             walletRepository: walletRepository,
                                             revenueRepository: revenueRepository)

        let restored = try #require(revenueRepository.revenues.first)
        #expect(restored.wallet == nil)
        #expect(restored.walletConfirmed == false)
    }

    // MARK: - Import Errors

    @Test func importRejectsFileThatIsNotABackup() throws {
        let url = try writeTemporaryFile(Data("not json".utf8))

        #expect(throws: BackupImporter.ImportError.notABackup(name: url.lastPathComponent)) {
            try BackupImporter().document(from: url)
        }
    }

    @Test func importRejectsUnreadableFile() {
        let url = URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString).moneytalks")

        #expect(throws: BackupImporter.ImportError.unreadableFile(name: url.lastPathComponent)) {
            try BackupImporter().document(from: url)
        }
    }

    @Test func importRejectsUnsupportedSchemaVersion() throws {
        let json = #"{"schemaVersion":99,"exportDate":"2025-10-09T00:00:00Z","wallets":[],"revenues":[]}"#
        let data = Data(json.utf8)

        #expect(throws: BackupImporter.ImportError.unsupportedSchemaVersion(99)) {
            try BackupImporter().document(from: data)
        }
    }

    @Test func importRejectsEmptyBackup() throws {
        let document = BackupDocument()
        let data = try BackupExporter().data(from: document)

        #expect(throws: BackupImporter.ImportError.emptyBackup) {
            try BackupImporter().document(from: data)
        }
    }

    @Test func importFailureSetsErrorMessageOnCoordinator() throws {
        let url = try writeTemporaryFile(Data("not json".utf8))

        let coordinator = BackupCoordinator()
        coordinator.importBackup(from: url,
                                     walletRepository: walletRepository,
                                     revenueRepository: revenueRepository)

        #expect(coordinator.errorMessage != nil)
        #expect(coordinator.resultMessage == nil)
    }

    // MARK: - Helpers

    private func makeWallet(
        id: UUID = UUID(),
        name: String = "Girokonto",
        imageName: String = "banknote.fill",
        isIncomming: Bool = true,
        color: Color = .blue
    ) -> Wallet {
        Wallet(id: id, name: name, imageName: imageName, isIncomming: isIncomming, color: color)
    }

    private func makeRevenue(amount: String = "-123,45") -> Revenue {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 12
        let day = Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 0)

        return Revenue(
            accountNumber: "DE12345678901234567890",
            bookingDate: day,
            valueDate: day,
            bookingText: "FOLGELASTSCHRIFT",
            purpose: "Streaming Abo",
            creditorIdentifier: "DE98ZZZ09999999999",
            mandateReference: "MND-4711",
            endToEndReference: "E2E-REF-0815",
            collectorReference: nil,
            originalDirectDebitAmount: Decimal(string: "9,99", locale: Locale(identifier: "de_DE")),
            directDebitReturnCosts: nil,
            beneficiaryOrPayer: "Streaming Anbieter GmbH",
            iban: "DE02120300000000202051",
            bic: "BYLADEM1001",
            amount: Decimal(string: amount.replacingOccurrences(of: ",", with: "."),
                            locale: Locale(identifier: "en_US_POSIX")) ?? 0,
            currency: "EUR",
            info: "Umsatz gebucht",
            category: "Abos",
            note: "Monthly subscription",
            walletConfirmed: false)
    }

    private func writeTemporaryFile(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).moneytalks")
        try data.write(to: url)
        return url
    }
}
