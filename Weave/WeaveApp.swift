//
//  WeaveApp.swift
//  Weave
//
//  A native macOS companion brain for Super Whisper Pro that automatically
//  transforms continuous voice streams into visually organized, topical workspaces.
//

import SwiftUI
import SwiftData

/// Main application entry point for Weave
@main
struct WeaveApp: App {
    /// SwiftData model container for persistence
    let modelContainer: ModelContainer
    
    /// Classification service for on-device topic detection
    let classificationService: ClassificationService
    
    init() {
        // Configure SwiftData with Project and Droplet models
        do {
            let schema = Schema([
                Project.self,
                Droplet.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            Log.app.info("SwiftData ModelContainer initialized successfully")
        } catch {
            Log.app.error("Failed to initialize SwiftData: \(error.localizedDescription)")
            fatalError("Could not initialize SwiftData ModelContainer: \(error)")
        }
        
        // Initialize classification service
        classificationService = ClassificationService()
        Log.app.info("Weave app initialized successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(classificationService)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Add app-specific menu commands
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    // Placeholder for update check
                }
            }
            
            CommandGroup(replacing: .help) {
                Button("Weave Help") {
                    // Placeholder for help
                }
            }
        }
    }
}
