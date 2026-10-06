//
//  WalletEditorView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 05.10.26.
//

import SwiftUI
import SwiftData

struct WalletEditorView: View {

    private static let imageNames = ["wallet.bifold",
                                     "creditcard.fill",
                                     "banknote.fill",
                                     "house.fill",
                                     "car.fill",
                                     "airplane",
                                     "cart.fill",
                                     "gift.fill"]

    private let editingWallet: Wallet?
    private let onSave: (Wallet) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var imageName: String
    @State private var color: Color
    @State private var isIncomming: Bool

    /// Creates a view that adds a new wallet.
    init(onSave: @escaping (Wallet) -> Void) {
        editingWallet = nil
        self.onSave = onSave
        _name = State(initialValue: "")
        _imageName = State(initialValue: Self.imageNames[0])
        _color = State(initialValue: .blue)
        _isIncomming = State(initialValue: false)
    }

    /// Creates a view that edits an existing wallet. Cancel keeps the stored wallet unchanged.
    init(editing wallet: Wallet, onSave: @escaping (Wallet) -> Void) {
        editingWallet = wallet
        self.onSave = onSave
        _name = State(initialValue: wallet.name)
        _imageName = State(initialValue: wallet.imageName)
        _color = State(initialValue: wallet.color)
        _isIncomming = State(initialValue: wallet.isIncomming)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Symbol", selection: $imageName) {
                    ForEach(Self.imageNames, id: \.self) { imageName in
                        Label(imageName, systemImage: imageName)
                            .tag(imageName)
                    }
                }
                ColorPicker("Color", selection: $color, supportsOpacity: false)
                Toggle("Incoming", isOn: $isIncomming)
            }
            .formStyle(.grouped)
            .navigationTitle(editingWallet == nil ? "Add Wallet" : "Edit Wallet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingWallet == nil ? "Add" : "Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(width: 320, height: 240)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let editedWallet = Wallet(id: editingWallet?.id ?? UUID(),
                                  name: trimmedName,
                                  imageName: imageName,
                                  isIncomming: isIncomming,
                                  color: color)
        onSave(editedWallet)
        dismiss()
    }
}

#Preview("Add") {
    WalletEditorView { _ in }
}

#Preview("Edit") {
    WalletEditorView(editing: Wallet(name: "Girokonto",
                                     imageName: "banknote.fill",
                                     isIncomming: true,
                                     color: .blue)) { _ in }
}