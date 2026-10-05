//
//  MoneyTalksApp.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import SwiftUI

@main
struct MoneyTalksApp: App {

    @State private var repository = RevenueRepository()
    @State private var importCoordinator = CSVImportCoordinator()

    var body: some Scene {
        WindowGroup {
            NavigationManagerView()
                .environment(repository)
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
}
