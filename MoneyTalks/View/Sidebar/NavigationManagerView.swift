//  NavigationManagerView.swift
//  Created by Holger Hinzberg on 16.11.22.

import SwiftUI
import SwiftData

struct NavigationManagerView: View {
    
    // @Environment(\.modelContext) private var modelContext
    // @Query private var settings : [Settings]
    // @Query private var config : [AppConfig]
    
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
    }
}

struct NavigationManagerView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: Revenue.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return NavigationManagerView()
            .modelContainer(container)
            .environment(RevenueRepository(modelContext: container.mainContext))
            .environment(CSVImportCoordinator())
    }
}
