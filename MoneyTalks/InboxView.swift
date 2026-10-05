//  ContentView.swift
//  MoneyTalks
//  Created by Holger Hinzberg on 25.09.26.

import SwiftUI
import UniformTypeIdentifiers

struct InboxView: View {

    @Environment(RevenueRepository.self) private var repository
    @Environment(CSVImportCoordinator.self) private var importCoordinator

    @State private var selectedRevenueID: Revenue.ID?
    @State private var isInspectorPresented = true

    var body: some View {
        @Bindable var importCoordinator = importCoordinator
        @Bindable var repository = repository

        Group {
            if repository.revenues.isEmpty {
                ContentUnavailableView("No Revenues",
                                       systemImage: "list.bullet.rectangle",
                                       description: Text("Use File ▸ Import CSV… to load transactions."))
            } else {
                List(selection: $selectedRevenueID) {
                    ForEach(repository.filteredRevenues) { revenue in
                        RevenueRowView(revenue: revenue)
                            .tag(revenue.id)
                    }
                    .onDelete(perform: removeRevenues)
                }
            }
        }
        .frame(minWidth: 640, minHeight: 400)
        .searchable(text: $repository.searchText, placement: .toolbar, prompt: "Search")
        .onChange(of: repository.searchText) {
            clearSelectionIfFilteredOut()
        }
        .inspector(isPresented: $isInspectorPresented) {
            inspector
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isInspectorPresented.toggle()
                } label: {
                    Label("Inspector", systemImage: "sidebar.trailing")
                }
                .help("Show or hide the inspector")
                .keyboardShortcut("i", modifiers: .command)
            }
        }
        .fileImporter(isPresented: $importCoordinator.isImportingCSV,
                      allowedContentTypes: [.commaSeparatedText, .plainText],
                      allowsMultipleSelection: true,
                      onCompletion: importFiles)
        .alert("CSV Import Failed",
               isPresented: Binding(get: { importCoordinator.errorMessage != nil },
                                    set: { if !$0 { importCoordinator.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importCoordinator.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var inspector: some View {
        if let revenue = selectedRevenue {
            RevenueDetailView(revenue: revenue)
                .inspectorColumnWidth(min: 280, ideal: 340, max: 440)
        } else {
            ContentUnavailableView("No Selection",
                                   systemImage: "sidebar.trailing",
                                   description: Text("Select a revenue to see its details."))
        }
    }

    private var selectedRevenue: Revenue? {
        guard let selectedRevenueID else { return nil }
        return repository.filteredRevenues.first { $0.id == selectedRevenueID }
    }

    private func clearSelectionIfFilteredOut() {
        guard let selectedRevenueID, selectedRevenue == nil else { return }
        self.selectedRevenueID = nil
    }

    private func importFiles(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            importCoordinator.importRevenues(from: urls, into: repository)
        case .failure(let error):
            guard !Self.isCancellation(error) else { return }
            importCoordinator.errorMessage = error.localizedDescription
        }
    }

    private func removeRevenues(atOffsets offsets: IndexSet) {
        let filteredRevenues = repository.filteredRevenues
        for offset in offsets where filteredRevenues.indices.contains(offset) {
            repository.remove(id: filteredRevenues[offset].id)
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        (error as? CocoaError)?.code == .userCancelled
    }
}

#Preview {
    InboxView()
        .environment(RevenueRepository())
        .environment(CSVImportCoordinator())
}
