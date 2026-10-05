//
//  AddWalletView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 05.10.26.
//

import SwiftUI
import SwiftData

public struct AddWalletView: View {

    private static let imageNames = ["wallet.bifold",
                                     "creditcard.fill",
                                     "banknote.fill",
                                     "house.fill",
                                     "car.fill",
                                     "airplane",
                                     "cart.fill",
                                     "gift.fill"]

    let onAdd: (Wallet) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var imageName = Self.imageNames[0]
    @State private var color: Color = .blue
    @State private var isIncomming = false

    public var body: some View {
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
        .frame(width: 320, height: 240)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    addWallet()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func addWallet() {
        let wallet = Wallet(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            imageName: imageName,
                            isIncomming: isIncomming,
                            color: color)
        onAdd(wallet)
        dismiss()
    }
}

#Preview {
    let container = try! ModelContainer(for: Revenue.self, Wallet.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let repository = WalletRepository(modelContext: container.mainContext)
    repository.add(Wallet(name: "Girokonto", imageName: "banknote.fill", isIncomming: true, color: .blue))
    repository.add(Wallet(name: "Kreditkarte", imageName: "creditcard.fill", isIncomming: false, color: .red))
    return WalletsView()
        .modelContainer(container)
        .environment(repository)
}
