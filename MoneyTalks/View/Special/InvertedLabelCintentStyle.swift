//
//  CustomLabelCintentStyle.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 09.10.26.
//

import SwiftUI

struct InvertedLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack() {
            configuration.label
                .foregroundStyle(.secondary)
            Spacer()
            configuration.content
                .foregroundStyle(.primary)
        }.padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
    }
}

extension LabeledContentStyle where Self == InvertedLabeledContentStyle {
    static var inverted: InvertedLabeledContentStyle { .init() }
}
