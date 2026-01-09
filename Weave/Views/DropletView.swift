//
//  DropletView.swift
//  Weave
//
//  View component for individual droplets.
//

import SwiftUI

/// A view displaying a single text droplet
struct DropletView: View {
    let droplet: Droplet
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Content text
            Text(droplet.content)
                .font(.subheadline)
                .lineLimit(isHovered ? nil : 4)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
            
            // Metadata row
            HStack(spacing: 8) {
                // Timestamp
                Text(droplet.formattedTimestamp)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Confidence badge
                if droplet.confidence > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: confidenceIcon)
                            .font(.caption2)
                        
                        Text(droplet.confidencePercentage)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(confidenceColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(confidenceColor.opacity(0.15), in: Capsule())
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onHover { hovering in
            isHovered = hovering
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
    
    // MARK: - Computed Properties
    
    private var confidenceColor: Color {
        if droplet.confidence >= 0.8 {
            return .green
        } else if droplet.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var confidenceIcon: String {
        if droplet.confidence >= 0.8 {
            return "checkmark.circle.fill"
        } else if droplet.confidence >= 0.6 {
            return "circle.fill"
        } else {
            return "questionmark.circle.fill"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        DropletView(droplet: Droplet(
            content: "I have an idea for a new feature that would automatically categorize voice notes based on semantic content analysis.",
            classifiedTopic: "Ideas",
            confidence: 0.92
        ))
        
        DropletView(droplet: Droplet(
            content: "Need to fix the bug with duplicate clipboard events.",
            classifiedTopic: "Bugs",
            confidence: 0.75
        ))
        
        DropletView(droplet: Droplet(
            content: "This is uncategorized content.",
            classifiedTopic: "Uncategorized",
            confidence: 0.4
        ))
    }
    .padding()
    .frame(width: 320)
    .background(Color.gray.opacity(0.2))
}
