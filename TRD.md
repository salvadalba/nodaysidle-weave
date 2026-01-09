# TRD

# Technical Requirements Document

## 🧭 System Context

Weave is a native macOS companion application for Super Whisper Pro. It monitors the system clipboard for dictation output, performs real-time semantic topic classification using on-device CoreML, and automatically routes content into topical project columns with fluid glass UI animations. The application is local-first with no server components, ensuring privacy and offline functionality.

## 🔌 API Contracts

### ClipboardListenerService

- **Method:** Event Stream
- **Path:** NSPasteboard.general
- **Auth:** None
- **Request:** N/A - System-level pasteboard observation
- **Response:** Published<String> - Emits new clipboard content on change
- **Errors:**
- PasteboardReadFailure
- EmptyContent
- NonTextContent

### ClassificationService.classify

- **Method:** Synchronous
- **Path:** Internal
- **Auth:** None
- **Request:** { text: String, knownTopics: [String] }
- **Response:** { topic: String, confidence: Double, timestamp: Date }
- **Errors:**
- TextTooShort
- NoTopicMatch
- ModelLoadFailure

### DropletRoutingService.route

- **Method:** Synchronous
- **Path:** Internal
- **Auth:** None
- **Request:** { droplet: Droplet, classification: ClassificationResult }
- **Response:** { targetProject: Project, isNewProject: Bool }
- **Errors:**
- ProjectNotFound
- InvalidClassification

### PersistenceService.createDroplet

- **Method:** Synchronous
- **Path:** Internal
- **Auth:** None
- **Request:** { content: String, projectId: PersistentIdentifier, timestamp: Date }
- **Response:** Droplet
- **Errors:**
- InvalidProject
- PersistenceFailure

### PersistenceService.createProject

- **Method:** Synchronous
- **Path:** Internal
- **Auth:** None
- **Request:** { name: String, color: Color?, topicKeywords: [String] }
- **Response:** Project
- **Errors:**
- DuplicateProjectName
- PersistenceFailure

### PersistenceService.fetchAll

- **Method:** Synchronous
- **Path:** Internal
- **Auth:** None
- **Request:** N/A
- **Response:** { projects: [Project], droplets: [Droplet] }
- **Errors:**
- FetchFailure

## 🧱 Modules

### ClipboardListenerService

- **Responsibilities:**
- Monitor NSPasteboard for changes
- Filter for Super Whisper Pro output
- Emit new text content via Combine publishers
- Debounce rapid clipboard events
- **Interfaces:**
- clipboardPublisher: AnyPublisher<String, Never>
- startMonitoring()
- stopMonitoring()
- **Depends on:**
- AppKit.NSPasteboard
- Combine

### ClassificationService

- **Responsibilities:**
- Load CoreML/NL classification model
- Perform zero-shot topic classification
- Cache classification results for identical text
- Return confidence scores for routing decisions
- **Interfaces:**
- classify(_: String, knownTopics: [String]) -> ClassificationResult
- loadModel() throws
- minimumConfidence: Double
- **Depends on:**
- CoreML
- NaturalLanguage

### DropletRoutingService

- **Responsibilities:**
- Map classification results to target projects
- Create new projects for unknown topics
- Handle routing conflicts and ambiguities
- Trigger UI animations for droplet movement
- **Interfaces:**
- route(droplet: Droplet, classification: ClassificationResult) -> RoutingDecision
- shouldCreateNewTopic(for: String) -> Bool
- **Depends on:**
- PersistenceService
- ClassificationService

### PersistenceService

- **Responsibilities:**
- SwiftData ModelContainer configuration
- CRUD operations for Projects and Droplets
- Query and fetch operations
- Schema migration handling
- **Interfaces:**
- createProject(_: ProjectInput) -> Project
- createDroplet(_: DropletInput) -> Droplet
- fetchProjects() -> [Project]
- fetchDroplets(for: Project) -> [Droplet]
- delete(_: PersistentModel)
- **Depends on:**
- SwiftData

### DropletAnimationService

- **Responsibilities:**
- Coordinate matchedGeometryEffect animations
- Manage droplet flight paths between columns
- Handle .ultraThinMaterial visual effects
- Orchestrate 60fps transition timing
- **Interfaces:**
- animate(droplet: Droplet, from: CGRect, to: CGRect) -> Void
- animationDuration: TimeInterval
- **Depends on:**
- SwiftUI

### WeaveApp

- **Responsibilities:**
- Application lifecycle management
- SwiftData ModelContainer initialization
- Root view coordination
- Service dependency injection
- **Interfaces:**
- main()
- init()
- **Depends on:**
- SwiftUI
- PersistenceService
- All service modules

### ContentView

- **Responsibilities:**
- Main window layout with project columns
- Display droplets within each project
- Handle drag-and-drop reorganization
- Present settings sheet
- **Interfaces:**
- body: some View
- projectColumns: [ProjectColumn]
- **Depends on:**
- SwiftUI
- DropletAnimationService
- PersistenceService

### SettingsView

- **Responsibilities:**
- Project creation and management UI
- Topic keyword configuration
- Classification confidence threshold adjustment
- Clipboard sensitivity settings
- **Interfaces:**
- body: some View
- saveSettings()
- **Depends on:**
- SwiftUI
- PersistenceService

## 🗃 Data Model Notes

- @Model class Project { id: PersistentIdentifier, name: String, color: Color?, topicKeywords: [String], createdAt: Date, droplets: [Droplet] }
- @Model class Droplet { id: PersistentIdentifier, content: String, classifiedTopic: String, confidence: Double, timestamp: Date, project: Project? }
- One-to-many relationship: Project.droplets contains all Droplets routed to that project
- SwiftData ModelContainer configured with [Project.self, Droplet.self] schema
- Queries use #Predicate for fetching project-specific droplets and chronological sorting

## 🔐 Validation & Security

- Clipboard input validation: Reject empty strings, non-text content, and content shorter than 3 characters
- Project name validation: Enforce 1-50 character length, disallow special characters that break filesystem operations
- Classification confidence threshold: Require minimum 0.6 confidence before routing to existing project
- Sandbox compliance: Request no network entitlements, file access only for app container
- App Transport Security: Disabled since no network operations are performed
- Code signing: Hardened runtime enabled for Mac App Store distribution
- Privacy: No telemetry, analytics, or data leaving the local device

## 🧯 Error Handling Strategy

Combine publishers receive errors via .catch() and redirect to error handling view. Clipboard read failures are logged and retried after 5-second backoff. Classification failures default to 'Uncategorized' project with user notification. Persistence failures present alert with option to export data as JSON. All errors are logged locally using OSLog with subsystem 'com.weave.app'.

## 🔭 Observability

- **Logging:** OSLog with subsystem 'com.weave.app' and categories: 'ClipboardListener', 'ClassificationService', 'PersistenceService', 'DropletRouting'. Log levels: .debug for clipboard events, .info for classifications, .error for failures.
- **Tracing:** Instruments .trace profiling for clipboard monitoring intervals and SwiftUI animation frame rates. No distributed tracing as single-process app.
- **Metrics:**
- Clipboard events processed per minute
- Classification latency in milliseconds
- Droplet routing accuracy (user corrections)
- Active project count
- Total droplet storage size

## ⚡ Performance Notes

- Clipboard polling interval: 250ms using NSTimer to balance responsiveness and CPU usage
- Classification batching: Process single clipboard events immediately, batch only during rapid-fire dictation (>3 events within 2 seconds)
- SwiftData fetch predicates: Use indexed queries on project_id and timestamp for sub-50ms retrieval
- View optimization: LazyVStack for project columns to render only visible droplets
- Animation budget: Target 16.67ms per frame (60fps) with matchedGeometryEffect transitions
- Memory ceiling: Purge classification cache after 1000 entries or 50MB heap allocation

## 🧪 Testing Strategy

### Unit

- ClipboardListenerService: Mock NSPasteboard and test publisher emission timing
- ClassificationService: Test topic classification with sample text and known topics
- DropletRoutingService: Verify routing logic with mock classification results
- PersistenceService: In-memory SwiftData container for CRUD operations

### Integration

- End-to-end clipboard detection to droplet persistence flow
- SwiftUI preview tests for ContentView and SettingsView layouts
- Animation timing verification for droplet flight paths

### E2E

- Manual testing with Super Whisper Pro dictation workflow
- Stress test: 100 consecutive clipboard events within 60 seconds
- Memory profiling during extended monitoring sessions (>1 hour)

## 🚀 Rollout Plan

- Phase 1: Implement core services (ClipboardListener, Classification, Persistence) with SwiftData stub
- Phase 2: Build basic SwiftUI UI with project columns and droplet display, no animations
- Phase 3: Integrate CoreML classification and validate routing accuracy with sample dictations
- Phase 4: Add .ultraThinMaterial styling and matchedGeometryEffect droplet animations
- Phase 5: Connect to actual Super Whisper Pro output and tune debouncing/polling
- Phase 6: Add settings UI for project management and confidence threshold adjustment
- Phase 7: Performance profiling, memory leak checks, and 60fps animation optimization
- Phase 8: Beta testing with real-world dictation workflows and bug fixes
- Phase 9: Mac App Store submission with screenshots, privacy questionnaire, and distribution

## ❓ Open Questions

- What specific pasteboard format does Super Whisper Pro write to? (needs reverse engineering or vendor documentation)
- Optimal classification confidence threshold? (requires user testing data)
- Should new project creation require user confirmation or happen automatically?
- How to handle dictations that span multiple topics? (segmentation strategy)
