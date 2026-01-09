//
//  Droplet.swift
//  Weave
//
//  SwiftData model representing a text droplet from voice dictation.
//

import Foundation
import SwiftData

/// A text droplet captured from Super Whisper Pro dictation
@Model
final class Droplet {
    /// Unique identifier for the droplet
    var id: UUID
    
    /// The text content of the dictation
    var content: String
    
    /// The topic classification assigned to this droplet
    var classifiedTopic: String
    
    /// Confidence score of the classification (0.0 - 1.0)
    var confidence: Double
    
    /// When the droplet was captured
    var timestamp: Date
    
    /// The project this droplet belongs to (many-to-one relationship)
    var project: Project?
    
    /// Initialize a new droplet
    /// - Parameters:
    ///   - content: The text content from dictation
    ///   - classifiedTopic: The assigned topic classification
    ///   - confidence: Classification confidence score
    ///   - project: The project to assign this droplet to
    init(
        content: String,
        classifiedTopic: String = "Uncategorized",
        confidence: Double = 0.0,
        project: Project? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.classifiedTopic = classifiedTopic
        self.confidence = confidence
        self.timestamp = Date()
        self.project = project
    }
    
    /// Formatted timestamp for display
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Confidence as a percentage string
    var confidencePercentage: String {
        String(format: "%.0f%%", confidence * 100)
    }
    
    /// Whether this droplet has high confidence (>= 0.6)
    var isHighConfidence: Bool {
        confidence >= 0.6
    }
}

// MARK: - Sample Data for Previews

extension Droplet {
    /// Sample droplet for previews
    static var sample: Droplet {
        Droplet(
            content: "I have an idea for a new feature that would allow users to automatically categorize their voice notes based on semantic content.",
            classifiedTopic: "Ideas",
            confidence: 0.87
        )
    }
    
    /// Multiple sample droplets for previews
    static var samples: [Droplet] {
        [
            Droplet(
                content: "Remember to fix the bug in the clipboard listener that causes duplicate events.",
                classifiedTopic: "Bugs",
                confidence: 0.92
            ),
            Droplet(
                content: "Need to schedule a meeting with the design team about the new UI mockups.",
                classifiedTopic: "Tasks",
                confidence: 0.75
            ),
            Droplet(
                content: "The glass morphism effect really makes the UI feel modern and premium.",
                classifiedTopic: "Ideas",
                confidence: 0.68
            )
        ]
    }
}
