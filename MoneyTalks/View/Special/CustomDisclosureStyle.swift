//
//  CustomDisclosureStyle.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 09.10.26.
//

import SwiftUI

struct CustomDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack {
                    configuration.label
                    Spacer()
                    Text(configuration.isExpanded ? "Show less" : "Show more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                .contentShape(.rect)
            }
            .buttonStyle(.bordered)

            if configuration.isExpanded {
                configuration.content.frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
        }
    }
}
