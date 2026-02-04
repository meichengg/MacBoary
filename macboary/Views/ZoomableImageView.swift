//
//  ZoomableImageView.swift
//  macboary
//
//  Created by MacBoary on 03/02/2026.
//

import SwiftUI
import AppKit

struct ZoomableImageView: View {
    let imagePath: String
    @Binding var isPresented: Bool
    
    @State private var image: NSImage?
    @State private var isLoading = true
    @State private var loadError: String?
    
    var body: some View {
        ZStack {
            // Background - Use a dark color or standard blur
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            if let image = image {
                // Native macOS ScrollView for smooth zoom & pan
                NativeZoomView(image: image, onClick: {  
                    // Click on image typically does nothing, or could toggle controls
                })
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
                
            } else if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(loadError ?? "Image not found")
                        .foregroundColor(.secondary)
                }
            }
            
            // Toolbar (floating at bottom)
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    // Info / Hint
                    Text("Scroll/Pinch: Zoom • Right-Click Drag: Pan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                        .frame(height: 16)
                    
                    // Close Button
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .cornerRadius(24)
                .shadow(radius: 10, y: 5)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: imagePath) { _, _ in
            image = nil
            loadImage()
        }
    }
    
    private func loadImage() {
        isLoading = true
        loadError = nil
        
        let path = imagePath
        
        // Run on detached task to ensure I/O doesn't block main thread
        Task.detached(priority: .userInitiated) {
            let loadedImage = await MainActor.run {
                // ClipboardManager.getImage might be safer to call on MainActor if it uses shared state
                // But we want to avoid blocking.
                // Assuming ClipboardManager is thread-safe OR we read file directly here
                return ClipboardManager.shared.getImage(named: path)
            }
            
            await MainActor.run {
                self.isLoading = false
                if let img = loadedImage {
                    self.image = img
                } else {
                    self.loadError = "Could not load image"
                }
            }
        }
    }
}

// MARK: - Native NSScrollView Wrapper

struct NativeZoomView: NSViewRepresentable {
    let image: NSImage
    var onClick: () -> Void
    
    func makeNSView(context: Context) -> ZoomScrollView {
        let scrollView = ZoomScrollView()
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.5
        scrollView.maxMagnification = 50.0 // Allow deep zoom
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        
        // Use custom clip view for centering
        let clipView = CenteringClipView()
        clipView.backgroundColor = .clear
        clipView.drawsBackground = false
        scrollView.contentView = clipView
        
        let imageView = NSImageView()
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        
        // Ensure image view is sized correctly
        imageView.frame = NSRect(origin: .zero, size: image.size)
        
        scrollView.documentView = imageView
        
        // Initial Zoom to Fit
        DispatchQueue.main.async {
            self.zoomToFit(scrollView: scrollView, imageSize: image.size)
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: ZoomScrollView, context: Context) {
        if let imageView = scrollView.documentView as? NSImageView {
            if imageView.image != image {
                imageView.image = image
                imageView.frame = NSRect(origin: .zero, size: image.size)
                
                // Rest zoom to fit
                DispatchQueue.main.async {
                    self.zoomToFit(scrollView: scrollView, imageSize: image.size)
                }
            }
        }
    }
    
    private func zoomToFit(scrollView: ZoomScrollView, imageSize: CGSize) {
        let containerSize = scrollView.bounds.size
        guard containerSize.width > 0, containerSize.height > 0, imageSize.width > 0, imageSize.height > 0 else { return }
        
        let widthRatio = containerSize.width / imageSize.width
        let heightRatio = containerSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio, 1.0) * 0.9
        
        scrollView.magnification = scale
        // Centering is handled by CenteringClipView automatically
    }
}

// Custom ClipView to keep document centered
class CenteringClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        if let documentView = self.documentView {
            if rect.size.width > documentView.frame.size.width {
                rect.origin.x = (documentView.frame.size.width - rect.size.width) / 2.0
            }
            if rect.size.height > documentView.frame.size.height {
                rect.origin.y = (documentView.frame.size.height - rect.size.height) / 2.0
            }
        }
        return rect
    }
}

class ZoomScrollView: NSScrollView {
    private var isDragging = false
    private var lastDragPoint: NSPoint = .zero
    
    override func scrollWheel(with event: NSEvent) {
        // Zoom on Scroll (centered at cursor)
        let multiplier: CGFloat = 0.1 // Adjust sensitivity
        let zoomChange = 1.0 + (event.deltaY * multiplier)
        let currentMag = self.magnification
        let newMagnification = max(minMagnification, min(maxMagnification, currentMag * zoomChange))
        
        // Get mouse position in DOCUMENT VIEW coordinates for proper centering
        let locationInWindow = event.locationInWindow
        let centerPoint = documentView?.convert(locationInWindow, from: nil) ?? NSPoint.zero
        
        // Apply zoom centered at mouse pointer
        self.setMagnification(newMagnification, centeredAt: centerPoint)
    }
    
    // MARK: - Right Click Drag to Pan
    
    override func rightMouseDown(with event: NSEvent) {
        isDragging = true
        lastDragPoint = event.locationInWindow
        NSCursor.closedHand.push()
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        
        let currentPoint = event.locationInWindow
        let deltaX = currentPoint.x - lastDragPoint.x
        let deltaY = currentPoint.y - lastDragPoint.y
        lastDragPoint = currentPoint
        
        // Adjust for magnification to keep drag synced with cursor
        let scale = self.magnification > 0.1 ? self.magnification : 1.0
        
        // Scroll logic (Inverted based on feedback): X-=, Y-=
        // Both subtract to implement "Hand Tool" (Direct Manipulation)
        var newOrigin = contentView.bounds.origin
        newOrigin.x -= (deltaX / scale)
        newOrigin.y -= (deltaY / scale)
        
        contentView.scroll(to: newOrigin)
        reflectScrolledClipView(contentView)
    }
    
    override func rightMouseUp(with event: NSEvent) {
        isDragging = false
        NSCursor.pop()
    }
    
    // KeyDown is now handled at Window level for reliability
}
