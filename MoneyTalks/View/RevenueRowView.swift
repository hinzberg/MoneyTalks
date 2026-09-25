//
//  RevenueRowView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 25.09.26.
//

import SwiftUI


public struct RevenueRowView: View {

    let revenue: Revenue

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {

                Text(revenue.beneficiaryOrPayer.isEmpty ? revenue.purpose : revenue.beneficiaryOrPayer)
                    .lineLimit(1)
                    .font(.title3)
                
                HStack(spacing: 4) {
                    Text(revenue.bookingDate, format: .dateTime.day().month(.twoDigits).year())
                    Text("·")
                    Text(revenue.bookingText)
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Text(revenue.amount, format: .currency(code: revenue.currency))
                .foregroundStyle(revenue.amount < 0 ? .red : .green)
                .font(.title3)
        }
    }
}
