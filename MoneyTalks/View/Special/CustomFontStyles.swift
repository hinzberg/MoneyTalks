//
//  CustomFontStyles.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 09.10.26.
//

import SwiftUI

extension View {
    func titleStyle() -> some View {
        modifier(Title())
    }
}

struct Title: ViewModifier {
    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .font(.system(size: 20, weight: .thin, design: .rounded))
            .tracking(1)
            .foregroundStyle(.primary)
    }
}

extension View {
    func subTitleStyle() -> some View {
        modifier(SubTitle())
    }
}

struct SubTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .tracking(1)
            .foregroundStyle(.secondary)
    }
}

extension View {
    func InspectorFontStyle() -> some View {
        modifier(InspectorFont())
    }
}

struct InspectorFont: ViewModifier {
    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .font(.system(size: 14, weight: .medium, design: .rounded))
    }
}
