//
//  RevenueRepositoryTests.swift
//  MoneyTalksTests
//
//  Created by Holger Hinzberg on 08.10.26.
//

import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import MoneyTalks

@MainActor
struct RevenueRepositoryTests {

    private let container: ModelContainer
    private let repository: RevenueRepository

    init() throws {
        container = try ModelContainer(
            for: Revenue.self, Wallet.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        repository = RevenueRepository(modelContext: container.mainContext)
    }

    // MARK: - Adding

    @Test func addStoresRevenueAndSaves() throws {
        let revenue = makeRevenue()

        #expect(repository.add(revenue))
        #expect(repository.revenues.count == 1)
        #expect(repository.revenues.first?.id == revenue.id)
        #expect(repository.lastSaveErrorMessage == nil)
        #expect(container.mainContext.hasChanges == false)
    }

    @Test func addSkipsStructurallyIdenticalRevenue() throws {
        // Revenue IDs are derived from the booking details, so identical
        // bookings produce the same id and are deduplicated.
        #expect(repository.add(makeRevenue()))
        #expect(!repository.add(makeRevenue()))

        #expect(repository.revenues.count == 1)
    }

    @Test func addStoresRevenuesWithDifferentDetailsSeparately() throws {
        #expect(repository.add(makeRevenue(purpose: "Miete")))
        #expect(repository.add(makeRevenue(purpose: "Strom")))

        #expect(repository.revenues.count == 2)
    }

    @Test func addContentsOfAddsOnlyNewRevenues() throws {
        let existing = makeRevenue(purpose: "Miete")
        repository.add(existing)

        let batch = [
            existing,
            makeRevenue(purpose: "Miete"),
            makeRevenue(purpose: "Strom")
        ]

        #expect(repository.add(contentsOf: batch) == 1)
        #expect(repository.revenues.count == 2)
    }

    // MARK: - setWallet

    @Test func setWalletAssignsWallet() throws {
        let revenue = makeRevenue()
        repository.add(revenue)
        let wallet = insertWallet()

        repository.setWallet(wallet, for: revenue)

        #expect(revenue.wallet?.id == wallet.id)
        #expect(container.mainContext.hasChanges == false)
    }

    @Test func setWalletWithNilClearsWalletAndRevokesConfirmation() throws {
        let revenue = makeRevenue()
        repository.add(revenue)
        repository.setWallet(insertWallet(), for: revenue)
        repository.setWalletConfirmed(true, for: revenue)

        repository.setWallet(nil, for: revenue)

        #expect(revenue.wallet == nil)
        #expect(!revenue.walletConfirmed)
    }

    @Test func setWalletWithSameWalletKeepsConfirmation() throws {
        let revenue = makeRevenue()
        repository.add(revenue)
        let wallet = insertWallet()
        repository.setWallet(wallet, for: revenue)
        repository.setWalletConfirmed(true, for: revenue)

        repository.setWallet(wallet, for: revenue)

        #expect(revenue.wallet?.id == wallet.id)
        #expect(revenue.walletConfirmed)
    }

    @Test func setWalletToDifferentWalletKeepsConfirmation() throws {
        let revenue = makeRevenue()
        repository.add(revenue)
        repository.setWallet(insertWallet(), for: revenue)
        repository.setWalletConfirmed(true, for: revenue)
        let newWallet = insertWallet(named: "Kreditkarte")

        repository.setWallet(newWallet, for: revenue)

        #expect(revenue.wallet?.id == newWallet.id)
        #expect(revenue.walletConfirmed)
    }

    // MARK: - setWalletConfirmed

    @Test func setWalletConfirmedTurnsConfirmationOnAndOff() throws {
        let revenue = makeRevenue()
        repository.add(revenue)

        repository.setWalletConfirmed(true, for: revenue)
        #expect(revenue.walletConfirmed)

        repository.setWalletConfirmed(false, for: revenue)
        #expect(!revenue.walletConfirmed)
        #expect(container.mainContext.hasChanges == false)
    }

    // MARK: - setNote

    @Test func setNoteStoresAndClearsNote() throws {
        let revenue = makeRevenue()
        repository.add(revenue)

        repository.setNote("Urlaub im September", for: revenue)
        #expect(revenue.note == "Urlaub im September")

        repository.setNote("", for: revenue)
        #expect(revenue.note.isEmpty)
        #expect(container.mainContext.hasChanges == false)
    }

    // MARK: - clearOrphanedConfirmations

    @Test func clearOrphanedConfirmationsUnconfirmsRevenuesWithoutWallet() throws {
        let wallet = insertWallet()
        let confirmedWithWallet = makeRevenue(purpose: "Mit Wallet", walletConfirmed: true)
        let unconfirmed = makeRevenue(purpose: "Offen")
        repository.add(contentsOf: [confirmedWithWallet, unconfirmed])
        repository.setWallet(wallet, for: confirmedWithWallet)
        repository.setWalletConfirmed(true, for: confirmedWithWallet)

        let walletRepository = WalletRepository(modelContext: container.mainContext)
        walletRepository.removeAll()
        #expect(confirmedWithWallet.wallet == nil)
        #expect(confirmedWithWallet.walletConfirmed)

        repository.clearOrphanedConfirmations()

        #expect(!confirmedWithWallet.walletConfirmed)
        #expect(!unconfirmed.walletConfirmed)
    }

    @Test func clearOrphanedConfirmationsKeepsConfirmedRevenuesWithWallet() throws {
        let revenue = makeRevenue(walletConfirmed: true)
        repository.add(revenue)
        repository.setWallet(insertWallet(), for: revenue)
        repository.setWalletConfirmed(true, for: revenue)

        repository.clearOrphanedConfirmations()

        #expect(revenue.wallet != nil)
        #expect(revenue.walletConfirmed)
        #expect(container.mainContext.hasChanges == false)
    }

    @Test func clearOrphanedConfirmationsIsNoOpWithoutOrphans() throws {
        let revenue = makeRevenue()
        repository.add(revenue)

        repository.clearOrphanedConfirmations()

        #expect(!revenue.walletConfirmed)
        #expect(container.mainContext.hasChanges == false)
    }

    // MARK: - Removing

    @Test func removeDeletesRevenue() throws {
        let revenue = makeRevenue()
        repository.add(revenue)

        repository.remove(revenue)

        #expect(repository.revenues.isEmpty)
        #expect(container.mainContext.hasChanges == false)
    }

    @Test func removeByIDDeletesOnlyMatchingRevenue() throws {
        let first = makeRevenue(purpose: "Miete")
        let second = makeRevenue(purpose: "Strom")
        repository.add(contentsOf: [first, second])

        repository.remove(id: first.id)

        #expect(repository.revenues.map(\.purpose) == ["Strom"])
    }

    @Test func removeByUnknownIDIsIgnored() throws {
        repository.add(makeRevenue())

        repository.remove(id: UUID())

        #expect(repository.revenues.count == 1)
    }

    @Test func removeAtIndexRemovesMatchingRevenue() throws {
        repository.add(makeRevenue(purpose: "Miete"))
        repository.add(makeRevenue(purpose: "Strom"))

        repository.remove(at: 0)

        #expect(repository.revenues.map(\.purpose) == ["Strom"])
    }

    @Test func removeAtIndexIgnoresOutOfBoundsIndex() throws {
        repository.add(makeRevenue())

        repository.remove(at: 5)

        #expect(repository.revenues.count == 1)
    }

    @Test func removeAtOffsetsRemovesOnlyGivenRevenues() throws {
        repository.add(makeRevenue(purpose: "Miete"))
        repository.add(makeRevenue(purpose: "Strom"))
        repository.add(makeRevenue(purpose: "Wasser"))

        repository.remove(atOffsets: IndexSet([0, 2]))

        #expect(repository.revenues.map(\.purpose) == ["Strom"])
    }

    @Test func removeAtOffsetsIgnoresOutOfBoundsOffsets() throws {
        repository.add(makeRevenue(purpose: "Miete"))
        repository.add(makeRevenue(purpose: "Strom"))

        repository.remove(atOffsets: IndexSet([0, 9]))

        #expect(repository.revenues.map(\.purpose) == ["Strom"])
    }

    @Test func removeAllEmptiesRepository() throws {
        repository.add(makeRevenue(purpose: "Miete"))
        repository.add(makeRevenue(purpose: "Strom"))

        repository.removeAll()

        #expect(repository.revenues.isEmpty)
    }

    // MARK: - filteredInboxRevenues

    @Test func filteredInboxWithoutSearchReturnsAllUnconfirmed() throws {
        let confirmed = makeRevenue(purpose: "Erstattung", walletConfirmed: true)
        let open = makeRevenue(purpose: "Rechnung")
        repository.add(contentsOf: [confirmed, open])

        #expect(repository.filteredInboxRevenues.map(\.id) == [open.id])
    }

    @Test func filteredInboxSearchMatchesPurposeBeneficiaryAndBookingText() throws {
        let telekom = makeRevenue(
            bookingText: "FOLGELASTSCHRIFT",
            purpose: "Mobilfunk",
            beneficiaryOrPayer: "Telekom Deutschland GmbH")
        let stadtwerke = makeRevenue(
            bookingText: "LASTSCHRIFT",
            purpose: "Strom Abschlag",
            beneficiaryOrPayer: "Stadtwerke Köln")
        repository.add(contentsOf: [telekom, stadtwerke])

        repository.searchText = "telekom"
        #expect(repository.filteredInboxRevenues.map(\.id) == [telekom.id])

        repository.searchText = "strom"
        #expect(repository.filteredInboxRevenues.map(\.id) == [stadtwerke.id])

        repository.searchText = "folge"
        #expect(repository.filteredInboxRevenues.map(\.id) == [telekom.id])

        repository.searchText = "LASTSCHRIFT"
        #expect(repository.filteredInboxRevenues.map(\.id) == [telekom.id, stadtwerke.id])
    }

    @Test func filteredInboxSearchNeverReturnsConfirmedRevenues() throws {
        let revenue = makeRevenue(purpose: "Mobilfunk", beneficiaryOrPayer: "Telekom")
        repository.add(revenue)
        repository.setWalletConfirmed(true, for: revenue)

        repository.searchText = "telekom"

        #expect(repository.filteredInboxRevenues.isEmpty)
    }

    @Test func filteredInboxSearchTreatsWhitespaceOnlyAsEmpty() throws {
        repository.add(makeRevenue(purpose: "Miete"))
        repository.add(makeRevenue(purpose: "Strom"))

        repository.searchText = "   "

        #expect(repository.filteredInboxRevenues.count == 2)
    }

    @Test func filteredInboxSearchWithoutMatchReturnsEmpty() throws {
        repository.add(makeRevenue(purpose: "Miete"))

        repository.searchText = "existiert nicht"

        #expect(repository.filteredInboxRevenues.isEmpty)
    }

    @Test func filteredInboxDateRangeIncludesStartAndEndDay() throws {
        let early = makeRevenue(bookingDate: Self.day(2026, 10, 10), purpose: "Zu früh")
        let onStart = makeRevenue(bookingDate: Self.day(2026, 10, 11), purpose: "Am Start")
        let onEnd = makeRevenue(bookingDate: Self.day(2026, 10, 20), purpose: "Am Ende")
        let late = makeRevenue(bookingDate: Self.day(2026, 10, 21), purpose: "Zu spät")
        repository.add(contentsOf: [early, onStart, onEnd, late])

        repository.filterStartDate = Self.day(2026, 10, 11)
        repository.filterEndDate = Self.day(2026, 10, 20)

        #expect(repository.filteredInboxRevenues.map(\.id) == [onStart.id, onEnd.id])
    }

    @Test func filteredInboxDateRangeWithoutBoundsReturnsAll() throws {
        let revenue = makeRevenue(bookingDate: Self.day(2026, 10, 15))
        repository.add(revenue)

        repository.filterStartDate = Self.day(2026, 10, 11)
        #expect(repository.filteredInboxRevenues.map(\.id) == [revenue.id])

        repository.filterStartDate = nil
        repository.filterEndDate = Self.day(2026, 10, 20)
        #expect(repository.filteredInboxRevenues.map(\.id) == [revenue.id])

        repository.filterEndDate = nil
        #expect(repository.filteredInboxRevenues.map(\.id) == [revenue.id])
    }

    @Test func filteredInboxWalletFilterOnlyReturnsRevenuesOfThatWallet() throws {
        let girokonto = insertWallet(named: "Girokonto")
        let tagesgeld = insertWallet(named: "Tagesgeld")
        let first = makeRevenue(purpose: "Erste")
        let second = makeRevenue(purpose: "Zweite")
        let third = makeRevenue(purpose: "Dritte")
        repository.add(contentsOf: [first, second, third])
        repository.setWallet(girokonto, for: first)
        repository.setWallet(tagesgeld, for: second)

        repository.filterWalletID = girokonto.id
        #expect(repository.filteredInboxRevenues.map(\.id) == [first.id])

        repository.filterWalletID = tagesgeld.id
        #expect(repository.filteredInboxRevenues.map(\.id) == [second.id])

        repository.filterWalletID = nil
        #expect(repository.filteredInboxRevenues.map(\.id) == [first.id, second.id, third.id])
    }

    @Test func filteredInboxCombinesWalletAndSearchFilter() throws {
        let girokonto = insertWallet(named: "Girokonto")
        let withWallet = makeRevenue(purpose: "Telekom Rechnung")
        let withoutWallet = makeRevenue(purpose: "Telekom Gutschrift")
        repository.add(contentsOf: [withWallet, withoutWallet])
        repository.setWallet(girokonto, for: withWallet)

        repository.filterWalletID = girokonto.id
        repository.searchText = "telekom"

        #expect(repository.filteredInboxRevenues.map(\.id) == [withWallet.id])
    }

    // MARK: - Fetching

    @Test func newRepositoryFetchesRevenuesSortedByBookingDateDescending() throws {
        let context = container.mainContext
        let older = makeRevenue(bookingDate: Date(timeIntervalSince1970: 1_000_000), purpose: "Älter")
        let newer = makeRevenue(bookingDate: Date(timeIntervalSince1970: 2_000_000), purpose: "Neuer")
        context.insert(older)
        context.insert(newer)
        try context.save()

        let fresh = RevenueRepository(modelContext: context)

        #expect(fresh.revenues.map(\.purpose) == ["Neuer", "Älter"])
    }

    // MARK: - Helpers

    private static func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    @discardableResult
    private func insertWallet(named name: String = "Girokonto") -> Wallet {
        let wallet = Wallet(name: name, imageName: "banknote.fill", isIncomming: true, color: .blue)
        container.mainContext.insert(wallet)
        return wallet
    }

    private func makeRevenue(
        bookingDate: Date = Date(timeIntervalSince1970: 1_790_745_600),
        bookingText: String = "Buchungstext",
        purpose: String = "Zweck",
        beneficiaryOrPayer: String = "Telekom Deutschland GmbH",
        amount: Decimal = -50,
        endToEndReference: String? = nil,
        category: String? = nil,
        note: String = "",
        walletConfirmed: Bool = false
    ) -> Revenue {
        Revenue(
            accountNumber: "DE43443500600018309831",
            bookingDate: bookingDate,
            valueDate: bookingDate,
            bookingText: bookingText,
            purpose: purpose,
            creditorIdentifier: nil,
            mandateReference: nil,
            endToEndReference: endToEndReference,
            collectorReference: nil,
            originalDirectDebitAmount: nil,
            directDebitReturnCosts: nil,
            beneficiaryOrPayer: beneficiaryOrPayer,
            iban: "DE07512108001095000911",
            bic: "SOGEDEFFXXX",
            amount: amount,
            currency: "EUR",
            info: "Info",
            category: category,
            note: note,
            walletConfirmed: walletConfirmed)
    }
}
