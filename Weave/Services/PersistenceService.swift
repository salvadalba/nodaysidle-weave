//
//  PersistenceService.swift
//  Weave
//
//  SwiftData CRUD operations for Projects and Droplets.
//

import Foundation
import SwiftData
import SwiftUI

/// Errors that can occur during persistence operations
enum PersistenceError: Error, LocalizedError {
    case duplicateProjectName(String)
    case invalidProject
    case persistenceFailure(String)
    case fetchFailure(String)
    case projectNameTooShort
    case projectNameTooLong
    
    var errorDescription: String? {
        switch self {
        case .duplicateProjectName(let name):
            return "A project named '\(name)' already exists"
        case .invalidProject:
            return "The specified project does not exist"
        case .persistenceFailure(let reason):
            return "Failed to save data: \(reason)"
        case .fetchFailure(let reason):
            return "Failed to fetch data: \(reason)"
        case .projectNameTooShort:
            return "Project name must be at least 1 character"
        case .projectNameTooLong:
            return "Project name must be 50 characters or less"
        }
    }
}

/// Service for SwiftData CRUD operations
@Observable
final class PersistenceService {
    /// The SwiftData model context
    private var modelContext: ModelContext?
    
    /// Configure the service with a model context
    func configure(with context: ModelContext) {
        self.modelContext = context
        Log.persistence.info("PersistenceService configured with ModelContext")
    }
    
    // MARK: - Project CRUD
    
    /// Create a new project
    /// - Parameters:
    ///   - name: The project name (1-50 characters)
    ///   - color: Optional color for the project
    ///   - topicKeywords: Keywords for topic matching
    /// - Returns: The created project
    @discardableResult
    func createProject(
        name: String,
        color: Color = Project.randomColor(),
        topicKeywords: [String] = []
    ) throws -> Project {
        guard let context = modelContext else {
            throw PersistenceError.persistenceFailure("ModelContext not configured")
        }
        
        // Validate name length
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw PersistenceError.projectNameTooShort
        }
        guard trimmedName.count <= 50 else {
            throw PersistenceError.projectNameTooLong
        }
        
        // Check for duplicate names
        let existingProjects = try fetchProjects()
        if existingProjects.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            throw PersistenceError.duplicateProjectName(trimmedName)
        }
        
        // Create project
        let project = Project(
            name: trimmedName,
            color: color,
            topicKeywords: topicKeywords
        )
        
        context.insert(project)
        try context.save()
        
        Log.persistence.info("Created project: \(trimmedName)")
        return project
    }
    
    /// Update an existing project
    func updateProject(
        _ project: Project,
        name: String? = nil,
        color: Color? = nil,
        topicKeywords: [String]? = nil
    ) throws {
        guard let context = modelContext else {
            throw PersistenceError.persistenceFailure("ModelContext not configured")
        }
        
        if let name = name {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                throw PersistenceError.projectNameTooShort
            }
            guard trimmedName.count <= 50 else {
                throw PersistenceError.projectNameTooLong
            }
            project.name = trimmedName
        }
        
        if let color = color {
            project.setColor(color)
        }
        
        if let topicKeywords = topicKeywords {
            project.topicKeywords = topicKeywords
        }
        
        try context.save()
        Log.persistence.info("Updated project: \(project.name)")
    }
    
    /// Fetch all projects
    func fetchProjects() throws -> [Project] {
        guard let context = modelContext else {
            throw PersistenceError.fetchFailure("ModelContext not configured")
        }
        
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// Find a project by name
    func findProject(byName name: String) throws -> Project? {
        let projects = try fetchProjects()
        return projects.first { $0.name.lowercased() == name.lowercased() }
    }
    
    /// Find a project by topic keyword
    func findProject(byKeyword keyword: String) throws -> Project? {
        let projects = try fetchProjects()
        return projects.first { project in
            project.topicKeywords.contains { $0.lowercased() == keyword.lowercased() }
        }
    }
    
    // MARK: - Droplet CRUD
    
    /// Create a new droplet
    /// - Parameters:
    ///   - content: The text content
    ///   - project: The project to add the droplet to
    ///   - classifiedTopic: The classified topic name
    ///   - confidence: Classification confidence score
    /// - Returns: The created droplet
    @discardableResult
    func createDroplet(
        content: String,
        project: Project,
        classifiedTopic: String,
        confidence: Double
    ) throws -> Droplet {
        guard let context = modelContext else {
            throw PersistenceError.persistenceFailure("ModelContext not configured")
        }
        
        let droplet = Droplet(
            content: content,
            classifiedTopic: classifiedTopic,
            confidence: confidence,
            project: project
        )
        
        context.insert(droplet)
        try context.save()
        
        Log.persistence.info("Created droplet in project '\(project.name)' with confidence \(confidence)")
        return droplet
    }
    
    /// Fetch droplets for a specific project
    func fetchDroplets(for project: Project) throws -> [Droplet] {
        guard let context = modelContext else {
            throw PersistenceError.fetchFailure("ModelContext not configured")
        }
        
        let projectId = project.persistentModelID
        let descriptor = FetchDescriptor<Droplet>(
            predicate: #Predicate { droplet in
                droplet.project?.persistentModelID == projectId
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// Fetch all droplets
    func fetchAllDroplets() throws -> [Droplet] {
        guard let context = modelContext else {
            throw PersistenceError.fetchFailure("ModelContext not configured")
        }
        
        let descriptor = FetchDescriptor<Droplet>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    // MARK: - Delete Operations
    
    /// Delete a project and all its droplets
    func deleteProject(_ project: Project) throws {
        guard let context = modelContext else {
            throw PersistenceError.persistenceFailure("ModelContext not configured")
        }
        
        let projectName = project.name
        context.delete(project)
        try context.save()
        
        Log.persistence.info("Deleted project: \(projectName)")
    }
    
    /// Delete a droplet
    func deleteDroplet(_ droplet: Droplet) throws {
        guard let context = modelContext else {
            throw PersistenceError.persistenceFailure("ModelContext not configured")
        }
        
        context.delete(droplet)
        try context.save()
        
        Log.persistence.info("Deleted droplet")
    }
    
    // MARK: - Utility
    
    /// Get or create the "Uncategorized" project
    func getOrCreateUncategorizedProject() throws -> Project {
        if let existing = try findProject(byName: "Uncategorized") {
            return existing
        }
        
        return try createProject(
            name: "Uncategorized",
            color: .gray,
            topicKeywords: ["uncategorized", "other", "misc"]
        )
    }
}

// MARK: - Environment Key

private struct PersistenceServiceKey: EnvironmentKey {
    static let defaultValue = PersistenceService()
}

extension EnvironmentValues {
    var persistenceService: PersistenceService {
        get { self[PersistenceServiceKey.self] }
        set { self[PersistenceServiceKey.self] = newValue }
    }
}
