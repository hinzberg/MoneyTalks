//
//  WalletPillView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 18.10.26.
//

import SwiftUI

struct WalletPillView: View {

    let wallet: Wallet

    var body: some View {
        Text(wallet.name)
            .subTitleStyle()
            .foregroundStyle(.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(wallet.color, lineWidth: 1)
            )
    }
}

#Preview {
    let wallet = Wallet(name: "Girokonto", imageName: "banknote.fill", isIncomming: true, color: .blue)
    return WalletPillView(wallet: wallet)
}
