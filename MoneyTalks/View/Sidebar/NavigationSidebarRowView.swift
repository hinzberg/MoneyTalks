//  NavigationSidebarRowView.swift
//  MoneyTalks
//  Created by Holger Hinzberg on 05.10.26.

import SwiftUI

struct SidebarRowView: View {
    let text: String
    let systemImage: String
    let count: Int?
    
    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.title2)
            .badge(
                Text("\(badgeText())")
                    .font(.title2)
            )
            .padding(EdgeInsets(top: 2, leading: 1, bottom: 2, trailing: 1))
    }
    
    func badgeText() -> String {
        if self.count == nil {
            return ""
        }
        return "\(count!)"
        
    }    
}
