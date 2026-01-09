//
//  ProjectColumn.swift
//  Weave
//
//  Reusable view component for individual project columns.
//

import SwiftUI
import SwiftData

/// A column displaying droplets for a single project
struct ProjectColumn: View {
    let project: Project
    let namespace: Namespace.ID
    let recentDroplets: [UUID]
    let onDeleteDroplet: (Droplet) -> Void
    
    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Droplets list
            if project.droplets.isEmpty {
                emptyState
            } else {
                dropletsScrollView
            }
        }
        .frame(width: 320)
        .frame(minHeight: 400)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(project.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isHovered ? 0.15 : 0.1), radius: isHovered ? 12 : 8, x: 0, y: 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(project.color)
                .frame(width: 12, height: 12)
            
            // Project name
            Text(project.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Droplet count
            Text("\(project.droplets.count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.2), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(project.color.opacity(0.1))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("No droplets yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Dictate content with keywords like:\n\(project.topicKeywords.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding()
    }
    
    // MARK: - Droplets List
    
    private var dropletsScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(sortedDroplets) { droplet in
                    DropletView(droplet: droplet)
                        .dropletInsertion(
                            isNew: recentDroplets.contains(droplet.id),
                            namespace: namespace,
                            dropletId: droplet.id
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                onDeleteDroplet(droplet)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(12)
        }
    }
    
    private var sortedDroplets: [Droplet] {
        project.droplets.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @Namespace var namespace
    
    let project = Project(
        name: "Ideas",
        color: .purple,
        topicKeywords: ["idea", "concept"]
    )
    
    ProjectColumn(
        project: project,
        namespace: namespace,
        recentDroplets: [],
        onDeleteDroplet: { _ in }
    )
    .padding()
    .frame(height: 500)
}
