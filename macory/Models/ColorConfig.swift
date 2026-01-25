
import SwiftUI

// Helper for storing colors
struct ColorConfig: Codable, Equatable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double
    
    var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    init(color: Color) {
        if let components = color.cgColor?.components {
            if components.count >= 3 {
                self.r = Double(components[0])
                self.g = Double(components[1])
                self.b = Double(components[2])
                self.a = components.count >= 4 ? Double(components[3]) : 1.0
            } else if components.count == 2 {
                // Grayscale
                self.r = Double(components[0])
                self.g = Double(components[0])
                self.b = Double(components[0])
                self.a = Double(components[1])
            } else {
                self.r = 0
                self.g = 0
                self.b = 0
                self.a = 1
            }
        } else {
             // Fallback
             self.r = 0; self.g = 0.5; self.b = 1; self.a = 1
        }
    }
    
    init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}
