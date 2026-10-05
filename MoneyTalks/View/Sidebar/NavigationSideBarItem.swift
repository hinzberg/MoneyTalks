//  NavigationSideBarItem.swift
//  Picture Downloader
//  Created by Holger Hinzberg on 16.11.22.

import Foundation

import SwiftUI

public enum NavigationSideBarItemIdentifier {
    case inbox
    case settings
}

public struct NavigationSideBarItem : Identifiable, Hashable {
    public var id : UUID = UUID()
    public var displayText : String
    public var imageName : String
    public var identifier : NavigationSideBarItemIdentifier
}
