//
//  ZoomWindowController.swift
//  macboary
//
//  Created by MacBoary on 03/02/2026.
//

import Cocoa
import SwiftUI

class ZoomWindowController: NSWindowController {
    static let shared = ZoomWindowController()
    
    private var hostingController: NSHostingController<ZoomableImageView>?
    private var currentImagePath: String = ""
    
    init() {
        // Create a borderless, transparent window
        let window = PreviewWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.85)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = true
        
        super.init(window: window)
        
        // Setup initial view
        let rootView = ZoomableImageView(
            imagePath: "",
            isPresented: Binding(
                get: { [weak self] in self?.window?.isVisible ?? false },
                set: { [weak self] show in if !show { self?.close() } }
            )
        )
        
        self.hostingController = NSHostingController(rootView: rootView)
        window.contentViewController = self.hostingController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(imagePath: String, from sourceRect: NSRect? = nil) {
        guard let window = window else { return }
        
        currentImagePath = imagePath
        
        // Update content
        let rootView = ZoomableImageView(
            imagePath: imagePath,
            isPresented: Binding(
                get: { [weak self] in self?.window?.isVisible ?? false },
                set: { [weak self] show in if !show { self?.close() } }
            )
        )
        self.hostingController?.rootView = rootView
        
        // Center on screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let width = min(screenRect.width * 0.9, 1600)
            let height = min(screenRect.height * 0.9, 1200)
            
            window.setFrame(NSRect(
                x: screenRect.midX - width/2,
                y: screenRect.midY - height/2,
                width: width,
                height: height
            ), display: true)
        }
        
        window.makeKeyAndOrderFront(nil)
        window.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    override func close() {
        super.close()
        currentImagePath = ""
        
        // Restore focus to main panel and search bar
        // We use showPanel() because it handles orderFront, makeKey, and focusing search
        FloatingPanelController.shared.showPanel()
    }
}

// Custom window subclass to allow borderless window to become key
class PreviewWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    // Handle shortcuts at Window level to ensure they work regardless of focus
    override func keyDown(with event: NSEvent) {
        // Esc (53) or Shift+Space (49 + shift)
        if event.keyCode == 53 || (event.keyCode == 49 && event.modifierFlags.contains(.shift)) {
            ZoomWindowController.shared.close()
            return
        }
        super.keyDown(with: event)
    }
}
