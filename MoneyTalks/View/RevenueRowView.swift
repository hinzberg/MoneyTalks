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
            VStack(alignment: .leading, spacing: 6) {

                Text(revenue.beneficiaryOrPayer.isEmpty ? revenue.purpose : revenue.beneficiaryOrPayer)
                    .titleStyle()
                
                HStack(spacing: 4) {
                    Text(revenue.bookingDate, format: .dateTime.day().month(.twoDigits).year())
                        .subTitleStyle()
                    Text("·")
                        .subTitleStyle()
                    Text(revenue.bookingText)
                        .subTitleStyle()
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Text(revenue.amount, format: .currency(code: revenue.currency))
                .foregroundStyle(revenue.amount < 0 ? .red : .green)
                .titleStyle()
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
    }
}


