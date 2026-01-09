//
//  Project.swift
//  Weave
//
//  SwiftData model representing a project column that contains droplets.
//

import Foundation
import SwiftUI
import SwiftData

/// A project column that contains categorized droplets
@Model
final class Project {
    /// Unique identifier for the project
    var id: UUID
    
    /// Display name for the project column
    var name: String
    
    /// Color for the project column (stored as hex string for SwiftData compatibility)
    var colorHex: String
    
    /// Keywords used for topic matching during classification
    var topicKeywords: [String]
    
    /// When the project was created
    var createdAt: Date
    
    /// Droplets that belong to this project (one-to-many relationship)
    @Relationship(deleteRule: .cascade, inverse: \Droplet.project)
    var droplets: [Droplet]
    
    /// Computed property to get SwiftUI Color from hex
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    /// Initialize a new project
    /// - Parameters:
    ///   - name: Display name for the project
    ///   - color: Color for the project column
    ///   - topicKeywords: Keywords used for topic matching
    init(
        name: String,
        color: Color = .blue,
        topicKeywords: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = color.toHex() ?? "#007AFF"
        self.topicKeywords = topicKeywords
        self.createdAt = Date()
        self.droplets = []
    }
    
    /// Set the project color
    func setColor(_ color: Color) {
        self.colorHex = color.toHex() ?? "#007AFF"
    }
}

// MARK: - Color Extension for Hex Conversion

extension Color {
    /// Create a Color from a hex string
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        guard hexSanitized.count == 6 else { return nil }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    /// Convert Color to hex string
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components else { return nil }
        
        let r = components.count >= 1 ? components[0] : 0
        let g = components.count >= 2 ? components[1] : 0
        let b = components.count >= 3 ? components[2] : 0
        
        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
}

// MARK: - Sample Data for Previews

extension Project {
    /// Generate a random project color
    static func randomColor() -> Color {
        let colors: [Color] = [
            .blue, .purple, .pink, .red, .orange,
            .yellow, .green, .teal, .cyan, .indigo
        ]
        return colors.randomElement() ?? .blue
    }
    
    /// Sample project for previews
    static var sample: Project {
        let project = Project(
            name: "Ideas",
            color: .purple,
            topicKeywords: ["idea", "concept", "brainstorm", "think"]
        )
        return project
    }
}
