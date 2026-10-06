//
//  DoubleClickNSView.swift
//  MoneyTalks
//
//  Created by Holger Hinzberg on 06.10.26.
//

import AppKit
import SwiftUI

/// Detects a double click on a list row without using a SwiftUI gesture.
/// SwiftUI tap gestures on List rows on macOS suppress the built-in click handling
/// (FB9067349), which is why the click is read from AppKit directly.
public struct DoubleClickDetector: NSViewRepresentable {

    let handler: () -> Void

    public func makeNSView(context: Context) -> DoubleClickNSView {
        DoubleClickNSView(handler: handler)
    }

    public func updateNSView(_ nsView: DoubleClickNSView, context: Context) {
        nsView.handler = handler
    }
}

public final class DoubleClickNSView: NSView {

    var handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount == 2 {
            handler()
        }
    }

    /// The view sits on top of the row, so the context menu of the row has to be
    /// looked up manually in the responder chain.
    override public func menu(for event: NSEvent) -> NSMenu? {
        var responder = nextResponder
        while let current = responder {
            if let view = current as? NSView, let menu = view.menu(for: event) {
                return menu
            }
            responder = current.nextResponder
        }
        return super.menu(for: event)
    }
}
