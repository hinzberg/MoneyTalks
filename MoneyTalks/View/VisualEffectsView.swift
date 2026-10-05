//  VisualEffectsView.swift
//  FileNameFixer
//  Created by Holger Hinzberg on 11.11.23.

import SwiftUI

struct VisualEffectView : NSViewRepresentable {

  func makeNSView(context: Self.Context) -> NSView {
      let view = NSVisualEffectView()
      view.state = NSVisualEffectView.State.active
      return view
  }

  func updateNSView(_ nsView: NSView, context: Context) { }
}
