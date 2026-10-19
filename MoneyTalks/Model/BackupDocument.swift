//
//  BackupDocument.swift
//  MoneyTalks
//

import Foundation
import UniformTypeIdentifiers

extension UTType {

    /// File type of MoneyTalks backup files (extension: moneytalks).
    /// Declared as an exported type in Info.plist.
    static let moneyTalksBackup = UTType(exportedAs: "de.hinzberg.MoneyTalks.backup", conformingTo: .json)
}

/// Root object of a backup file. The JSON mirrors the current model schema;
/// schemaVersion is checked on import so future formats fail with a clear message.
struct BackupDocument: Codable, Equatable {

    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var exportDate: Date
    var wallets: [WalletBackupEntry]
    var revenues: [RevenueBackupEntry]

    init(exportDate: Date = Date(),
         wallets: [WalletBackupEntry] = [],
         revenues: [RevenueBackupEntry] = []) {
        self.schemaVersion = Self.currentSchemaVersion
        self.exportDate = exportDate
        self.wallets = wallets
        self.revenues = revenues
    }
}

struct WalletBackupEntry: Codable, Equatable {

    var id: UUID
    var name: String
    var imageName: String
    var colorHex: String
    var isIncomming: Bool

    init(id: UUID, name: String, imageName: String, colorHex: String, isIncomming: Bool) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.colorHex = colorHex
        self.isIncomming = isIncomming
    }

    init(_ wallet: Wallet) {
        self.init(id: wallet.id,
                  name: wallet.name,
                  imageName: wallet.imageName,
                  colorHex: wallet.colorHex,
                  isIncomming: wallet.isIncomming)
    }

    func makeWallet() -> Wallet {
        let wallet = Wallet(id: id, name: name, imageName: imageName, isIncomming: isIncomming)
        wallet.colorHex = colorHex
        return wallet
    }
}

struct RevenueBackupEntry: Codable, Equatable {

    var id: UUID
    var accountNumber: String
    var bookingDate: Date
    var valueDate: Date
    var bookingText: String
    var purpose: String
    var creditorIdentifier: String?
    var mandateReference: String?
    var endToEndReference: String?
    var collectorReference: String?
    var originalDirectDebitAmount: Decimal?
    var directDebitReturnCosts: Decimal?
    var beneficiaryOrPayer: String
    var iban: String
    var bic: String
    var amount: Decimal
    var currency: String
    var info: String
    var category: String?
    var note: String
    var walletID: UUID?
    var walletConfirmed: Bool

    init(_ revenue: Revenue) {
        self.id = revenue.id
        self.accountNumber = revenue.accountNumber
        self.bookingDate = revenue.bookingDate
        self.valueDate = revenue.valueDate
        self.bookingText = revenue.bookingText
        self.purpose = revenue.purpose
        self.creditorIdentifier = revenue.creditorIdentifier
        self.mandateReference = revenue.mandateReference
        self.endToEndReference = revenue.endToEndReference
        self.collectorReference = revenue.collectorReference
        self.originalDirectDebitAmount = revenue.originalDirectDebitAmount
        self.directDebitReturnCosts = revenue.directDebitReturnCosts
        self.beneficiaryOrPayer = revenue.beneficiaryOrPayer
        self.iban = revenue.iban
        self.bic = revenue.bic
        self.amount = revenue.amount
        self.currency = revenue.currency
        self.info = revenue.info
        self.category = revenue.category
        self.note = revenue.note
        self.walletID = revenue.wallet?.id
        self.walletConfirmed = revenue.walletConfirmed
    }

    /// Recreates the revenue exactly as it was exported, including its
    /// deterministic id. The wallet relationship is resolved by the importer.
    func makeRevenue() -> Revenue {
        let revenue = Revenue(accountNumber: accountNumber,
                              bookingDate: bookingDate,
                              valueDate: valueDate,
                              bookingText: bookingText,
                              purpose: purpose,
                              creditorIdentifier: creditorIdentifier,
                              mandateReference: mandateReference,
                              endToEndReference: endToEndReference,
                              collectorReference: collectorReference,
                              originalDirectDebitAmount: originalDirectDebitAmount,
                              directDebitReturnCosts: directDebitReturnCosts,
                              beneficiaryOrPayer: beneficiaryOrPayer,
                              iban: iban,
                              bic: bic,
                              amount: amount,
                              currency: currency,
                              info: info,
                              category: category,
                              note: note,
                              walletConfirmed: walletConfirmed)
        revenue.id = id
        return revenue
    }
}
