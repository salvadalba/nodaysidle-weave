//
//  DropletRoutingService.swift
//  Weave
//
//  Routes classified content to appropriate project columns.
//

import Foundation
import SwiftUI
import Combine

/// Result of a routing decision
struct RoutingDecision {
    /// The target project for the droplet
    let targetProject: Project
    
    /// Whether a new project was created for this routing
    let isNewProject: Bool
    
    /// The created droplet
    let droplet: Droplet
}

/// Animation details for routing visualization
struct RoutingAnimation {
    let droplet: Droplet
    let fromRect: CGRect
    let toRect: CGRect
    let project: Project
}

/// Errors that can occur during routing
enum RoutingError: Error, LocalizedError {
    case projectNotFound
    case invalidClassification
    case routingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .projectNotFound:
            return "No matching project found for the classification"
        case .invalidClassification:
            return "Classification result is invalid"
        case .routingFailed(let reason):
            return "Routing failed: \(reason)"
        }
    }
}

/// Service that routes droplets to project columns based on classification
@Observable
final class DropletRoutingService {
    // MARK: - Dependencies
    
    private let persistenceService: PersistenceService
    private let classificationService: ClassificationService
    
    // MARK: - Publishers
    
    /// Publisher for routing animations
    var animationPublisher: AnyPublisher<RoutingAnimation, Never> {
        animationSubject.eraseToAnyPublisher()
    }
    
    private let animationSubject = PassthroughSubject<RoutingAnimation, Never>()
    
    // MARK: - Configuration
    
    /// Whether to automatically create new projects for unknown topics
    var autoCreateProjects: Bool = true
    
    /// Available colors for new projects
    private let projectColors: [Color] = [
        .blue, .purple, .pink, .red, .orange,
        .yellow, .green, .teal, .cyan, .indigo
    ]
    
    // MARK: - Initialization
    
    init(persistenceService: PersistenceService, classificationService: ClassificationService) {
        self.persistenceService = persistenceService
        self.classificationService = classificationService
        Log.routing.info("DropletRoutingService initialized")
    }
    
    // MARK: - Routing Methods
    
    /// Route content to the appropriate project based on classification
    /// - Parameters:
    ///   - content: The text content to route
    ///   - fromRect: Optional source rectangle for animation
    /// - Returns: The routing decision with created droplet
    func route(content: String, fromRect: CGRect? = nil) throws -> RoutingDecision {
        // Get known topics from existing projects
        let projects = try persistenceService.fetchProjects()
        let knownTopics = projects.flatMap { [$0.name] + $0.topicKeywords }
        
        // Classify the content
        let classification = classificationService.classifyWithFallback(content, knownTopics: knownTopics)
        
        Log.routing.info("Routing content classified as '\(classification.topic)' with confidence \(classification.confidence)")
        
        // Find or create target project
        let (targetProject, isNew) = try findOrCreateProject(
            for: classification,
            existingProjects: projects
        )
        
        // Create the droplet
        let droplet = try persistenceService.createDroplet(
            content: content,
            project: targetProject,
            classifiedTopic: classification.topic,
            confidence: classification.confidence
        )
        
        let decision = RoutingDecision(
            targetProject: targetProject,
            isNewProject: isNew,
            droplet: droplet
        )
        
        // Emit animation event if source rect provided
        if let fromRect = fromRect {
            // Placeholder toRect - will be updated by UI
            let animation = RoutingAnimation(
                droplet: droplet,
                fromRect: fromRect,
                toRect: .zero,
                project: targetProject
            )
            animationSubject.send(animation)
        }
        
        Log.routing.info("Routed droplet to project '\(targetProject.name)' (new: \(isNew))")
        
        return decision
    }
    
    /// Determine if a new project should be created for a topic
    func shouldCreateNewProject(for topic: String, confidence: Double) -> Bool {
        // Create new project if:
        // 1. Auto-create is enabled
        // 2. Confidence is above minimum threshold
        // 3. Topic is not "Uncategorized"
        return autoCreateProjects &&
               confidence >= classificationService.minimumConfidence &&
               topic.lowercased() != "uncategorized"
    }
    
    // MARK: - Private Methods
    
    /// Find an existing project or create a new one based on classification
    private func findOrCreateProject(
        for classification: ClassificationResult,
        existingProjects: [Project]
    ) throws -> (Project, Bool) {
        
        // Try to find by direct name match
        if let project = existingProjects.first(where: {
            $0.name.lowercased() == classification.topic.lowercased()
        }) {
            return (project, false)
        }
        
        // Try to find by keyword match
        if let project = existingProjects.first(where: { project in
            project.topicKeywords.contains { keyword in
                keyword.lowercased() == classification.topic.lowercased()
            }
        }) {
            return (project, false)
        }
        
        // Decide whether to create new project or use Uncategorized
        if shouldCreateNewProject(for: classification.topic, confidence: classification.confidence) {
            // Create new project with the topic name
            let newProject = try persistenceService.createProject(
                name: classification.topic,
                color: randomProjectColor(),
                topicKeywords: [classification.topic.lowercased()]
            )
            return (newProject, true)
        } else {
            // Use Uncategorized project
            let uncategorized = try persistenceService.getOrCreateUncategorizedProject()
            return (uncategorized, false)
        }
    }
    
    /// Get a random color for a new project
    private func randomProjectColor() -> Color {
        projectColors.randomElement() ?? .blue
    }
    
    /// Move a droplet to a different project
    func moveDroplet(_ droplet: Droplet, to project: Project) throws {
        droplet.project = project
        droplet.classifiedTopic = project.name
        
        Log.routing.info("Moved droplet to project '\(project.name)'")
    }
}

// MARK: - Environment Key

private struct DropletRoutingServiceKey: EnvironmentKey {
    static let defaultValue: DropletRoutingService? = nil
}

extension EnvironmentValues {
    var routingService: DropletRoutingService? {
        get { self[DropletRoutingServiceKey.self] }
        set { self[DropletRoutingServiceKey.self] = newValue }
    }
}
