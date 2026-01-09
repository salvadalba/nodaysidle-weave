//
//  ContentView.swift
//  Weave
//
//  Main content view with project columns and droplet display.
//

import SwiftUI
import SwiftData

/// Main view displaying project columns and droplets
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .forward) private var projects: [Project]
    
    @State private var viewModel = ContentViewModel()
    @State private var showSettings = false
    @State private var showAddProject = false
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
            
            if projects.isEmpty {
                emptyState
            } else {
                projectColumnsView
            }
            
            // Monitoring status indicator
            monitoringIndicator
        }
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showAddProject) {
            AddProjectSheet(viewModel: viewModel)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            viewModel.configure(with: modelContext)
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .windowBackgroundColor).opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "drop.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Projects Yet")
                .font(.title)
                .fontWeight(.medium)
            
            Text("Start dictating with Super Whisper Pro\nor create a project manually")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button {
                    showAddProject = true
                } label: {
                    Label("Create Project", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button {
                    createSampleProjects()
                } label: {
                    Label("Add Sample Data", systemImage: "wand.and.stars")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Project Columns
    
    private var projectColumnsView: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                // Use flexible grid that wraps based on available width
                let columnWidth: CGFloat = 320
                let spacing: CGFloat = 20
                let columns = max(1, Int(geometry.size.width / (columnWidth + spacing)))
                
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(columnWidth), spacing: spacing), count: columns),
                    alignment: .leading,
                    spacing: spacing
                ) {
                    ForEach(projects) { project in
                        ProjectColumn(
                            project: project,
                            namespace: animationNamespace,
                            recentDroplets: viewModel.recentDroplets,
                            onDeleteDroplet: { droplet in
                                viewModel.deleteDroplet(droplet)
                            }
                        )
                    }
                }
                .padding(24)
            }
        }
    }
    
    // MARK: - Monitoring Indicator
    
    private var monitoringIndicator: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isMonitoring ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.isMonitoring ? "Listening" : "Paused")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if viewModel.dropletsProcessed > 0 {
                        Text("• \(viewModel.dropletsProcessed) captured")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .onTapGesture {
                    viewModel.toggleMonitoring()
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.toggleMonitoring()
            } label: {
                Label(
                    viewModel.isMonitoring ? "Stop Listening" : "Start Listening",
                    systemImage: viewModel.isMonitoring ? "pause.circle.fill" : "play.circle.fill"
                )
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                showAddProject = true
            } label: {
                Label("Add Project", systemImage: "plus")
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
    }
    
    // MARK: - Sample Data
    
    private func createSampleProjects() {
        let samples = [
            ("Ideas", Color.purple, ["idea", "concept", "brainstorm", "think"]),
            ("Tasks", Color.blue, ["task", "todo", "do", "work"]),
            ("Bugs", Color.red, ["bug", "fix", "error", "issue"]),
            ("Notes", Color.green, ["note", "remember", "memo"])
        ]
        
        for (name, color, keywords) in samples {
            viewModel.createProject(name: name, color: color, keywords: keywords)
        }
        
        Log.ui.info("Created sample projects")
    }
}

// MARK: - Add Project Sheet

struct AddProjectSheet: View {
    let viewModel: ContentViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName = ""
    @State private var projectColor = Color.blue
    @State private var keywords = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Project")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // Form
            Form {
                TextField("Project Name", text: $projectName)
                
                ColorPicker("Color", selection: $projectColor)
                
                TextField("Keywords (comma separated)", text: $keywords)
                    .help("Keywords used for topic matching during classification")
            }
            .formStyle(.grouped)
            .padding()
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("Create Project") {
                    createProject()
                }
                .buttonStyle(.borderedProminent)
                .disabled(projectName.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }
    
    private func createProject() {
        let keywordList = keywords
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        viewModel.createProject(
            name: projectName,
            color: projectColor,
            keywords: keywordList
        )
        
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Project.self, Droplet.self], inMemory: true)
}
