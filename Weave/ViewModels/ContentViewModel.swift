//
//  ContentViewModel.swift
//  Weave
//
//  Main view model that coordinates all services for clipboard-to-droplet flow.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

/// Main view model coordinating clipboard monitoring, classification, routing, and persistence
@Observable
final class ContentViewModel {
    // MARK: - Services
    
    let clipboardListener: ClipboardListenerService
    let classificationService: ClassificationService
    let persistenceService: PersistenceService
    var routingService: DropletRoutingService?
    let animationService: DropletAnimationService
    
    // MARK: - State
    
    /// Whether the app is actively monitoring clipboard
    var isMonitoring: Bool = false
    
    /// Most recent clipboard content
    var lastClipboardContent: String?
    
    /// Recently added droplets (for animation)
    var recentDroplets: [UUID] = []
    
    /// Error message to display
    var errorMessage: String?
    
    /// Show error alert
    var showError: Bool = false
    
    /// Number of droplets processed this session
    var dropletsProcessed: Int = 0
    
    // MARK: - Private
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        self.clipboardListener = ClipboardListenerService()
        self.classificationService = ClassificationService()
        self.persistenceService = PersistenceService()
        self.animationService = DropletAnimationService()
        
        Log.app.info("ContentViewModel initialized")
    }
    
    /// Configure with model context (called from view)
    func configure(with modelContext: ModelContext) {
        persistenceService.configure(with: modelContext)
        
        // Create routing service now that persistence is configured
        routingService = DropletRoutingService(
            persistenceService: persistenceService,
            classificationService: classificationService
        )
        
        // Set up clipboard subscription
        setupClipboardSubscription()
        
        Log.app.info("ContentViewModel configured with ModelContext")
    }
    
    // MARK: - Clipboard Monitoring
    
    /// Start monitoring clipboard
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        clipboardListener.startMonitoring()
        isMonitoring = true
        
        Log.app.info("Started clipboard monitoring")
    }
    
    /// Stop monitoring clipboard
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        clipboardListener.stopMonitoring()
        isMonitoring = false
        
        Log.app.info("Stopped clipboard monitoring")
    }
    
    /// Toggle monitoring state
    func toggleMonitoring() {
        if isMonitoring {
            stopMonitoring()
        } else {
            startMonitoring()
        }
    }
    
    // MARK: - Manual Actions
    
    /// Process text content manually (for testing or direct input)
    func processContent(_ content: String) {
        guard let routingService else {
            showError(message: "Routing service not configured")
            return
        }
        
        do {
            let decision = try routingService.route(content: content)
            handleRoutingSuccess(decision)
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    /// Create a new project
    func createProject(name: String, color: Color, keywords: [String]) {
        do {
            try persistenceService.createProject(
                name: name,
                color: color,
                topicKeywords: keywords
            )
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    /// Delete a project
    func deleteProject(_ project: Project) {
        do {
            try persistenceService.deleteProject(project)
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    /// Delete a droplet
    func deleteDroplet(_ droplet: Droplet) {
        do {
            try persistenceService.deleteDroplet(droplet)
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupClipboardSubscription() {
        clipboardListener.clipboardPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] content in
                self?.handleClipboardContent(content)
            }
            .store(in: &cancellables)
    }
    
    private func handleClipboardContent(_ content: String) {
        lastClipboardContent = content
        
        guard let routingService else {
            Log.app.warning("Routing service not available, skipping clipboard content")
            return
        }
        
        do {
            let decision = try routingService.route(content: content)
            handleRoutingSuccess(decision)
        } catch {
            Log.routing.error("Routing failed: \(error.localizedDescription)")
            showError(message: "Failed to route content: \(error.localizedDescription)")
        }
    }
    
    private func handleRoutingSuccess(_ decision: RoutingDecision) {
        dropletsProcessed += 1
        
        // Track for animation
        recentDroplets.append(decision.droplet.id)
        
        // Clean up old recent droplets
        if recentDroplets.count > 10 {
            recentDroplets.removeFirst()
        }
        
        Log.app.info("Droplet routed to '\(decision.targetProject.name)' (new project: \(decision.isNewProject))")
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        Log.app.error("Error: \(message)")
    }
}
