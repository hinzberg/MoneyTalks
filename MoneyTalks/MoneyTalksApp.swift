//
//  MoneyTalksApp.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import SwiftData
import SwiftUI

@main
struct MoneyTalksApp: App {

    @State private var repository: RevenueRepository
    @State private var walletRepository: WalletRepository
    @State private var importCoordinator = CSVImportCoordinator()

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    init() {
        let container = Self.makeModelContainer()
        let context = ModelContext(container)
        modelContainer = container
        modelContext = context
        _repository = State(initialValue: RevenueRepository(modelContext: context))
        _walletRepository = State(initialValue: WalletRepository(modelContext: context))
    }

    var body: some Scene {
        WindowGroup {
            NavigationManagerView()
                .modelContainer(modelContainer)
                .modelContext(modelContext)
                .environment(repository)
                .environment(walletRepository)
                .environment(importCoordinator)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Import CSV…") {
                    importCoordinator.isImportingCSV = true
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
        }
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Revenue.self, Wallet.self)
        } catch {
            return try! ModelContainer(for: Revenue.self, Wallet.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }
}