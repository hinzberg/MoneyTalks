//  NavigationManagerView.swift
//  Created by Holger Hinzberg on 16.11.22.

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct NavigationManagerView: View {
    
    // @Environment(\.modelContext) private var modelContext
    // @Query private var settings : [Settings]
    // @Query private var config : [AppConfig]

    @Environment(BackupCoordinator.self) private var backupCoordinator
    @Environment(RevenueRepository.self) private var revenueRepository
    @Environment(WalletRepository.self) private var walletRepository
    
    var sideBarItems : [NavigationSideBarItem]
    init()
    {
        sideBarItems =  [
            NavigationSideBarItem(displayText: "Inbox", imageName: "tray.and.arrow.down", identifier: .inbox),
            NavigationSideBarItem(displayText: "Wallets", imageName: "wallet.bifold", identifier: .wallet),
            NavigationSideBarItem(displayText: "Settings", imageName: "gear", identifier: .settings)
        ]
    }
    
    @State var sideBarVisibility : NavigationSplitViewVisibility = .doubleColumn
    @State var selectedIdentifier : NavigationSideBarItemIdentifier = .inbox
    
    var body: some View {
        @Bindable var backupCoordinator = backupCoordinator
        NavigationSplitView(columnVisibility: $sideBarVisibility) {
            List(sideBarItems, selection: $selectedIdentifier) { item in
                NavigationLink (value:  item.identifier) {
                    SidebarRowView(text: item.displayText, systemImage: item.imageName, count: nil)
                }
            }.listStyle(.sidebar)
                .background(VisualEffectView())
        } detail: {
            switch selectedIdentifier {
            case .inbox:
                InboxView()
            case .wallet:
                WalletsView()
            case .settings:
                SettingsView()
            }
        }
        .fileExporter(isPresented: $backupCoordinator.isExporting,
                      document: backupCoordinator.exportDocument,
                      contentType: .moneyTalksBackup,
                      defaultFilename: backupCoordinator.exportFileName) { result in
            backupCoordinator.exportFinished(result)
        }
        .fileImporter(isPresented: $backupCoordinator.isImporting,
                      allowedContentTypes: [.moneyTalksBackup],
                      allowsMultipleSelection: false) { result in
            backupCoordinator.importFinished(result,
                                             walletRepository: walletRepository,
                                             revenueRepository: revenueRepository)
        }
        .alert("Backup Failed",
               isPresented: Binding(get: { backupCoordinator.errorMessage != nil },
                                    set: { if !$0 { backupCoordinator.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(backupCoordinator.errorMessage ?? "")
        }
        .alert("Backup",
               isPresented: Binding(get: { backupCoordinator.resultMessage != nil },
                                    set: { if !$0 { backupCoordinator.resultMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(backupCoordinator.resultMessage ?? "")
        }
    }
}

struct NavigationManagerView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: Revenue.self, Wallet.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return NavigationManagerView()
            .modelContainer(container)
            .environment(RevenueRepository(modelContext: container.mainContext))
            .environment(WalletRepository(modelContext: container.mainContext))
            .environment(CSVImportCoordinator())
            .environment(BackupCoordinator())
    }
}
