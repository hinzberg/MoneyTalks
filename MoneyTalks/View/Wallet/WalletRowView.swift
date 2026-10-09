//  WalletRowView.swift
//  MoneyTalks
//  Created by Holger Hinzberg on 06.10.26.

import SwiftUI

public struct WalletRowView: View {

    let wallet: Wallet

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: wallet.imageName)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(wallet.color, in: Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(wallet.name)
                    .titleStyle()
                Text(wallet.isIncomming ? "Incoming" : "Outgoing")
                    .subTitleStyle()
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
        }
        .padding(EdgeInsets(top: 2, leading: 1, bottom: 2, trailing: 1))
    }
}
