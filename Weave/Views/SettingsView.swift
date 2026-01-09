//
//  SettingsView.swift
//  Weave
//
//  Settings UI for project management and app preferences.
//

import SwiftUI
import SwiftData

/// Settings view for managing projects and configuration
struct SettingsView: View {
    let viewModel: ContentViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .forward) private var projects: [Project]
    
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Tab picker
            Picker("Settings", selection: $selectedTab) {
                Text("Projects").tag(0)
                Text("Classification").tag(1)
                Text("Clipboard").tag(2)
                Text("About").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            TabView(selection: $selectedTab) {
                projectsTab.tag(0)
                classificationTab.tag(1)
                clipboardTab.tag(2)
                aboutTab.tag(3)
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 500, height: 450)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Settings")
                .font(.headline)
            Spacer()
            Button("Done") {
                dismiss()
            }
        }
        .padding()
    }
    
    // MARK: - Projects Tab
    
    private var projectsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Projects")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if projects.isEmpty {
                Text("No projects created yet")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                List {
                    ForEach(projects) { project in
                        ProjectRow(project: project, onDelete: {
                            viewModel.deleteProject(project)
                        })
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding()
    }
    
    // MARK: - Classification Tab
    
    private var classificationTab: some View {
        Form {
            Section("Confidence Threshold") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Minimum Confidence")
                        Spacer()
                        Text("\(Int(viewModel.classificationService.minimumConfidence * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.classificationService.minimumConfidence },
                            set: { viewModel.classificationService.minimumConfidence = $0 }
                        ),
                        in: 0.3...0.9,
                        step: 0.05
                    )
                    
                    Text("Lower values route more content to existing projects. Higher values require stronger topic matches.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Section("Auto-Create Projects") {
                if let routingService = viewModel.routingService {
                    Toggle(
                        "Automatically create projects for new topics",
                        isOn: Binding(
                            get: { routingService.autoCreateProjects },
                            set: { routingService.autoCreateProjects = $0 }
                        )
                    )
                    
                    Text("When enabled, new projects are created for topics that don't match existing keywords.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Clipboard Tab
    
    private var clipboardTab: some View {
        Form {
            Section("Polling Interval") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Check Every")
                        Spacer()
                        Text("\(Int(viewModel.clipboardListener.pollingInterval * 1000))ms")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.clipboardListener.pollingInterval },
                            set: { viewModel.clipboardListener.setPollingInterval($0) }
                        ),
                        in: 0.1...0.5,
                        step: 0.05
                    )
                    
                    Text("Faster polling detects clipboard changes quicker but uses more CPU.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Section("Debounce Duration") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Wait Before Processing")
                        Spacer()
                        Text("\(Int(viewModel.clipboardListener.debounceDuration * 1000))ms")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.clipboardListener.debounceDuration },
                            set: { viewModel.clipboardListener.debounceDuration = $0 }
                        ),
                        in: 0.2...1.0,
                        step: 0.1
                    )
                    
                    Text("Longer debounce combines rapid clipboard changes into single events.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Section("Minimum Content Length") {
                Stepper(
                    "\(viewModel.clipboardListener.minimumCharacterCount) characters",
                    value: Binding(
                        get: { viewModel.clipboardListener.minimumCharacterCount },
                        set: { viewModel.clipboardListener.minimumCharacterCount = $0 }
                    ),
                    in: 1...20
                )
                
                Text("Content shorter than this will be ignored.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - About Tab
    
    private var aboutTab: some View {
        VStack(spacing: 20) {
            Image(systemName: "drop.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("Weave")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("A native macOS companion brain for Super Whisper Pro that automatically transforms continuous voice streams into visually organized, topical workspaces.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Local-first • Privacy-focused • No cloud")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Text("Built with SwiftUI, SwiftData, and NaturalLanguage")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
}

// MARK: - Project Row

struct ProjectRow: View {
    let project: Project
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(project.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.body)
                
                Text("\(project.droplets.count) droplets • \(project.topicKeywords.count) keywords")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .alert("Delete Project?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This will delete \"\(project.name)\" and all its \(project.droplets.count) droplets. This cannot be undone.")
        }
    }
}

#Preview {
    SettingsView(viewModel: ContentViewModel())
        .modelContainer(for: [Project.self, Droplet.self], inMemory: true)
}
