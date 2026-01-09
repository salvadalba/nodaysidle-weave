# TASKS

# Tasks Plan — Weave

## 📌 Global Assumptions

- Super Whisper Pro outputs plain text to NSPasteboard
- User has granted Accessibility permissions for clipboard monitoring
- macOS 14.0+ is minimum deployment target
- Solo developer handling all implementation
- No external API dependencies or network requirements
- User testing will inform optimal confidence threshold
- App Store distribution via Apple Developer account

## ⚠️ Risks

- Super Whisper Pro clipboard format may require reverse engineering
- NSPasteboard polling may impact battery life on portable Macs
- CoreML classification accuracy may vary across use cases
- App Store review may challenge clipboard monitoring behavior
- 60fps animation target may not be achievable on older Macs
- Memory leaks could accumulate during extended monitoring sessions
- User may find automatic project creation confusing without confirmation

## 🧩 Epics

## Foundation & Xcode Setup

**Goal:** Create the Xcode project structure with all necessary configurations and dependencies

### ✅ Create Xcode project with macOS app target (0.5)

Initialize a new macOS app project in Xcode using SwiftUI, set bundle identifier, deployment target (macOS 14+), and basic Info.plist configurations

**Acceptance Criteria**

- Xcode project builds successfully
- App launches with empty window
- Bundle identifier set to com.weave.app
- macOS 14.0+ deployment target set

**Dependencies**
_None_

### ✅ Configure SwiftData schema (1)

Create Project and Droplet @Model classes with proper relationships, indexes, and SwiftData ModelContainer configuration

**Acceptance Criteria**

- Project model with id, name, color, topicKeywords, createdAt, droplets properties
- Droplet model with id, content, classifiedTopic, confidence, timestamp, project properties
- One-to-many relationship established
- ModelContainer configured in App entry point

**Dependencies**
_None_

### ✅ Set up OSLog infrastructure (0.5)

Create logging utility with subsystem 'com.weave.app' and categories for each service module

**Acceptance Criteria**

- Logger extension with categories: ClipboardListener, ClassificationService, PersistenceService, DropletRouting
- Configurable log levels
- Unified logging interface

**Dependencies**
_None_

## Clipboard Monitoring

**Goal:** Build a service that monitors NSPasteboard for Super Whisper Pro dictation output

### ✅ Implement ClipboardListenerService base structure (1)

Create ClipboardListenerService class with Combine publisher for clipboard changes, startMonitoring/stopMonitoring methods

**Acceptance Criteria**

- ClipboardListenerService class created
- clipboardPublisher: AnyPublisher<String, Never> defined
- startMonitoring() and stopMonitoring() methods defined
- Combine framework imported

**Dependencies**

- Create Xcode project with macOS app target

### ✅ Implement NSPasteboard polling with NSTimer (1.5)

Set up 250ms polling interval using NSTimer, read NSPasteboard.general.string(forType: .string), detect changes from previous value

**Acceptance Criteria**

- NSTimer runs at 250ms intervals
- Detects clipboard changes correctly
- Only emits new content (not duplicates)
- Can be started and stopped

**Dependencies**

- Implement ClipboardListenerService base structure

### ✅ Add debouncing for rapid clipboard events (1)

Implement Combine debounce operator to handle rapid-fire dictation (>3 events within 2 seconds triggers batching mode)

**Acceptance Criteria**

- Debounce configured for normal operations
- Batching mode activates for rapid events
- Publisher emits debounced values

**Dependencies**

- Implement NSPasteboard polling with NSTimer

### ✅ Add clipboard validation and error handling (1)

Validate clipboard content (min 3 chars, text only, not empty), handle PasteboardReadFailure errors, implement 5-second backoff retry

**Acceptance Criteria**

- Rejects empty strings
- Rejects content < 3 characters
- Rejects non-text content
- Errors logged and retried after 5 seconds

**Dependencies**

- Add debouncing for rapid clipboard events

## On-Device Classification

**Goal:** Build CoreML + NaturalLanguage service for zero-shot topic classification

### ✅ Create ClassificationService structure (0.5)

Define ClassificationService class with classify() method signature, ClassificationResult struct, and minimumConfidence property

**Acceptance Criteria**

- ClassificationService class created
- ClassificationResult struct with topic, confidence, timestamp
- classify(_:knownTopics:) -> ClassificationResult method
- minimumConfidence: Double property set to 0.6

**Dependencies**

- Configure SwiftData schema

### ✅ Implement NaturalLanguage tagger for zero-shot classification (2)

Use NLTagger with NLModel for on-device text classification, load model on init, return confidence scores

**Acceptance Criteria**

- NLTagger configured for classification
- Model loads successfully
- Returns topic and confidence score
- Throws ModelLoadFailure on error

**Dependencies**

- Create ClassificationService structure

### ✅ Add classification result caching (1)

Implement in-memory cache for identical text inputs to avoid redundant classification, purge after 1000 entries or 50MB

**Acceptance Criteria**

- Cache stores classification results by text hash
- Cache checked before classification
- Cache purges at 1000 entries or 50MB
- Cache hits return immediately

**Dependencies**

- Implement NaturalLanguage tagger for zero-shot classification

### ✅ Add error handling for edge cases (1)

Handle TextTooShort, NoTopicMatch errors, default to 'Uncategorized' on failure with user notification

**Acceptance Criteria**

- TextTooShort thrown for < 3 char input
- NoTopicMatch thrown when confidence below threshold
- Failures default to 'Uncategorized'
- User notification shown on fallback

**Dependencies**

- Add classification result caching

## Persistence Layer

**Goal:** Implement SwiftData CRUD operations for Projects and Droplets

### ✅ Create PersistenceService with ModelContainer (1)

Set up SwiftData ModelContainer with [Project.self, Droplet.self] schema, create PersistenceService class with container access

**Acceptance Criteria**

- PersistenceService class created
- ModelContainer configured with Project and Droplet models
- Shared container instance accessible

**Dependencies**

- Configure SwiftData schema

### ✅ Implement createProject CRUD operation (1)

Add createProject method that validates name (1-50 chars), checks for duplicates, creates and persists Project

**Acceptance Criteria**

- createProject(name:color:topicKeywords:) method
- 1-50 character name validation
- Duplicate name check throws DuplicateProjectName
- Project persisted successfully

**Dependencies**

- Create PersistenceService with ModelContainer

### ✅ Implement createDroplet CRUD operation (1)

Add createDroplet method that validates project exists, creates Droplet with classification data, persists to database

**Acceptance Criteria**

- createDroplet(content:projectId:timestamp:) method
- Project validation throws InvalidProject
- Droplet persisted with relationship
- Returns created Droplet

**Dependencies**

- Implement createProject CRUD operation

### ✅ Implement fetch operations with predicates (1.5)

Add fetchProjects() and fetchDroplets(for: Project) methods using #Predicate with indexed queries for sub-50ms retrieval

**Acceptance Criteria**

- fetchProjects() returns all projects
- fetchDroplets(for:) returns project-specific droplets
- Uses #Predicate for queries
- Indexed on project_id and timestamp

**Dependencies**

- Implement createDroplet CRUD operation

### ✅ Implement delete operation (0.5)

Add delete(_:) method that handles cascade deletion for projects with droplets, throws PersistenceFailure on error

**Acceptance Criteria**

- delete(_:) accepts PersistentModel
- Cascade deletes droplets when project deleted
- Throws PersistenceFailure on error

**Dependencies**

- Implement fetch operations with predicates

## Droplet Routing Logic

**Goal:** Build service that maps classifications to projects and handles routing decisions

### ✅ Create DropletRoutingService structure (0.5)

Define DropletRoutingService class with route() method, RoutingDecision struct, and dependency injection for PersistenceService and ClassificationService

**Acceptance Criteria**

- DropletRoutingService class created
- route(droplet:classification:) -> RoutingDecision method
- RoutingDecision struct with targetProject and isNewProject
- Dependencies injected via init

**Dependencies**

- Implement fetch operations with predicates
- Add error handling for edge cases

### ✅ Implement routing logic for existing projects (1.5)

Map classification results to existing projects based on topicKeywords, match when confidence >= minimumConfidence, throw ProjectNotFound if no match

**Acceptance Criteria**

- Finds matching project by topic
- Requires confidence >= 0.6
- Returns RoutingDecision with existing project
- Throws ProjectNotFound when no match

**Dependencies**

- Create DropletRoutingService structure

### ✅ Implement new project creation for unknown topics (1)

Add shouldCreateNewTopic() method, create project with topic name when confidence < threshold, assign random color, auto-generate keywords

**Acceptance Criteria**

- shouldCreateNewTopic(for:) returns Bool
- New project created for unknown topics
- Random color assigned
- Topic name used as project name

**Dependencies**

- Implement routing logic for existing projects

### ✅ Add animation trigger coordination (1)

Emit animation events via Combine publisher when droplet is routed, include source and destination CGRect for flight path

**Acceptance Criteria**

- Animation publisher emits on route
- Includes from and to CGRect
- Publisher type: AnyPublisher<RoutingAnimation, Never>

**Dependencies**

- Implement new project creation for unknown topics

## Base UI Layout

**Goal:** Build SwiftUI interface with project columns and droplet display

### ✅ Create WeaveApp entry point (1)

Implement main App struct, initialize SwiftData ModelContainer, set up ContentView as root view, handle dependency injection

**Acceptance Criteria**

- WeaveApp struct conforms to App
- ModelContainer initialized on launch
- ContentView set as root
- Services injected into environment

**Dependencies**

- Implement delete operation

### ✅ Create ContentView with column layout (1.5)

Build main view with horizontal scrolling project columns using LazyHStack, display projects from SwiftData

**Acceptance Criteria**

- ContentView with LazyHStack layout
- Displays projects horizontally
- Fetches projects from SwiftData
- Empty state shown when no projects

**Dependencies**

- Create WeaveApp entry point

### ✅ Create ProjectColumn component (1)

Build reusable view component for individual project columns, display droplets using LazyVStack, show project name and color

**Acceptance Criteria**

- ProjectColumn struct accepts Project
- LazyVStack for droplets
- Project name displayed
- Project color indicator shown

**Dependencies**

- Create ContentView with column layout

### ✅ Create DropletView component (1)

Build view component for individual droplets, display content text, timestamp, and confidence badge

**Acceptance Criteria**

- DropletView struct accepts Droplet
- Content text displayed
- Timestamp formatted and shown
- Confidence badge visible

**Dependencies**

- Create ProjectColumn component

## Fluid Glass Aesthetics

**Goal:** Apply .ultraThinMaterial styling and visual polish to the UI

### ✅ Apply .ultraThinMaterial to project columns (0.5)

Add .background(.ultraThinMaterial) modifier to ProjectColumn, configure corner radius and shadow

**Acceptance Criteria**

- ProjectColumn has .ultraThinMaterial background
- Corner radius of 12px
- Subtle shadow applied

**Dependencies**

- Create DropletView component

### ✅ Style DropletView with glass morphism (0.5)

Apply .ultraThinMaterial to droplets, add transparency, subtle borders, and inner shadow effects

**Acceptance Criteria**

- DropletView has glass morphism styling
- Translucency effect visible
- Subtle border on each droplet

**Dependencies**

- Apply .ultraThinMaterial to project columns

### ✅ Add color theming for projects (0.5)

Apply project color to column headers and droplet accents, ensure contrast with glass background

**Acceptance Criteria**

- Project color visible in header
- Droplet accents use project color
- Sufficient contrast maintained

**Dependencies**

- Style DropletView with glass morphism

## Droplet Animations

**Goal:** Implement matchedGeometryEffect animations for droplet flight paths

### ✅ Create DropletAnimationService (1)

Build service to coordinate animations, manage flight path calculations, handle 60fps timing

**Acceptance Criteria**

- DropletAnimationService class created
- animate(droplet:from:to:) method
- animationDuration property set to 0.3s

**Dependencies**

- Add animation trigger coordination

### ✅ Implement matchedGeometryEffect namespace (1)

Set up @Namespace property in ContentView, pass to child views for shared animation coordinates

**Acceptance Criteria**

- @Namespace in ContentView
- Passed to ProjectColumn
- Passed to DropletView

**Dependencies**

- Create DropletAnimationService

### ✅ Add droplet insertion animation (2)

Animate new droplets flying from input area to target column using matchedGeometryEffect with spring timing

**Acceptance Criteria**

- New droplets animate into columns
- Spring timing applied
- Flight path follows curved trajectory

**Dependencies**

- Implement matchedGeometryEffect namespace

### ✅ Add droplet reordering animation (1.5)

Animate droplet movement between columns when classification changes or user manually reorganizes

**Acceptance Criteria**

- Droplets animate between columns
- Smooth transition on reclassification
- Manual drag-drop animated

**Dependencies**

- Add droplet insertion animation

## Service Integration

**Goal:** Connect all services for end-to-end clipboard to droplet flow

### ✅ Integrate ClipboardListener with ClassificationService (1)

Subscribe to clipboardPublisher, pipe new text to classify(), handle results in main view model

**Acceptance Criteria**

- Clipboard changes trigger classification
- Results published to view model
- Errors handled gracefully

**Dependencies**

- Add clipboard validation and error handling

### ✅ Integrate ClassificationService with DropletRoutingService (1)

Pass classification results to router, receive routing decisions, create droplets via PersistenceService

**Acceptance Criteria**

- Classifications trigger routing
- Routing decisions processed
- Droplets created and persisted

**Dependencies**

- Integrate ClipboardListener with ClassificationService
- Implement new project creation for unknown topics

### ✅ Wire up complete flow to SwiftUI (2)

Connect service chain to ContentView, update UI reactively when droplets are added, trigger animations

**Acceptance Criteria**

- Clipboard text appears as droplet
- Droplet flies to correct column
- UI updates automatically
- Animations play smoothly

**Dependencies**

- Integrate ClassificationService with DropletRoutingService
- Add droplet reordering animation

## Settings & Configuration

**Goal:** Build settings UI for project management and app preferences

### ✅ Create SettingsView structure (1)

Build settings sheet with sections for projects, classification, and clipboard settings

**Acceptance Criteria**

- SettingsView struct created
- Sheet presentation from ContentView
- Three tab sections

**Dependencies**

- Wire up complete flow to SwiftUI

### ✅ Implement project creation UI (1.5)

Add form for new project name, color picker, topic keywords input, save button creates project via PersistenceService

**Acceptance Criteria**

- Project name text field
- Color picker
- Topic keywords input
- Save creates project

**Dependencies**

- Create SettingsView structure

### ✅ Implement project management UI (1.5)

List existing projects with edit and delete options, confirm delete alert, handle validation errors

**Acceptance Criteria**

- Projects listed with color and name
- Edit button opens form
- Delete shows confirmation
- Cascade delete handled

**Dependencies**

- Implement project creation UI

### ✅ Add classification confidence threshold slider (1)

Slider control for minimumConfidence (0.0-1.0), updates ClassificationService, displays current value

**Acceptance Criteria**

- Slider from 0.0 to 1.0
- Current value displayed
- Updates ClassificationService
- Persists to UserDefaults

**Dependencies**

- Implement project management UI

### ✅ Add clipboard sensitivity settings (1)

Control for polling interval (100ms-500ms), debounce duration, updates ClipboardListenerService

**Acceptance Criteria**

- Polling interval slider (100-500ms)
- Debounce duration control
- Updates ClipboardListenerService
- Persists to UserDefaults

**Dependencies**

- Add classification confidence threshold slider

## Testing & Quality

**Goal:** Ensure app reliability and performance through testing

### ✅ Unit test ClipboardListenerService (2)

Mock NSPasteboard, test publisher emission timing, debouncing, validation

**Acceptance Criteria**

- Mock pasteboard tests pass
- Emission timing verified
- Debounce behavior tested
- Validation tests pass

**Dependencies**

- Add clipboard validation and error handling

### ✅ Unit test ClassificationService (2)

Test classification with sample text, known topics, confidence thresholds, cache behavior

**Acceptance Criteria**

- Classification accuracy tests
- Confidence threshold tests
- Cache hit/miss tests
- Error handling tests

**Dependencies**

- Add classification result caching

### ✅ Unit test DropletRoutingService (2)

Mock PersistenceService, test routing logic, new project creation, animation triggers

**Acceptance Criteria**

- Routing logic tests pass
- New project creation tested
- Animation trigger verified
- Edge cases covered

**Dependencies**

- Add animation trigger coordination

### ✅ Unit test PersistenceService (2)

In-memory SwiftData container, test CRUD operations, validation, cascade deletion

**Acceptance Criteria**

- Create/read/update/delete tests
- Validation tests
- Cascade delete tests
- Error handling tests

**Dependencies**

- Implement delete operation

### ✅ UI preview tests (1)

SwiftUI previews for ContentView, SettingsView, components with sample data

**Acceptance Criteria**

- ContentView preview renders
- SettingsView preview renders
- Component previews work
- Sample data displays correctly

**Dependencies**

- Add color theming for projects

### ✅ Stress test clipboard processing (1.5)

Test with 100 consecutive clipboard events within 60 seconds, verify no crashes, memory stable

**Acceptance Criteria**

- 100 events processed without crash
- Memory usage stable
- All droplets persisted
- UI remains responsive

**Dependencies**

- Wire up complete flow to SwiftUI

### ✅ Performance profiling (2)

Use Instruments to profile animation frame rates, clipboard polling overhead, classification latency

**Acceptance Criteria**

- 60fps animation maintained
- Clipboard polling < 5% CPU
- Classification < 100ms
- Memory < 100MB baseline

**Dependencies**

- Add droplet reordering animation

## Launch Preparation

**Goal:** Prepare app for Mac App Store distribution

### ✅ Create app icon and assets (2)

Design 1024x1024 app icon, generate all required sizes, add to Xcode asset catalog

**Acceptance Criteria**

- 1024x1024 icon source
- All sizes generated
- Added to Assets.xcassets
- Appears in dock and menu bar

**Dependencies**
_None_

### ✅ Configure App Store Connect metadata (2)

Write app name, subtitle (150 chars), description (4000 chars), keywords (100 chars), screenshots

**Acceptance Criteria**

- App name finalized
- Subtitle written
- Description written
- Keywords selected
- Screenshots captured (5 variations)

**Dependencies**

- Create app icon and assets

### ✅ Complete privacy questionnaire (0.5)

Answer App Store privacy questions, confirm no data collection, local-only processing

**Acceptance Criteria**

- Privacy questionnaire completed
- No data collection declared
- Local-only processing documented

**Dependencies**
_None_

### ✅ Configure code signing and provisioning (1)

Set up Apple Developer certificate, provisioning profile, hardened runtime entitlements

**Acceptance Criteria**

- Development certificate configured
- Distribution certificate configured
- Provisioning profile created
- Hardened runtime enabled

**Dependencies**
_None_

### ✅ Build release archive (1)

Create release build, validate for App Store, upload to App Store Connect

**Acceptance Criteria**

- Archive builds successfully
- App Store validation passes
- Uploaded to App Store Connect

**Dependencies**

- Configure code signing and provisioning
- Configure App Store Connect metadata

## ❓ Open Questions

- What specific pasteboard format does Super Whisper Pro write to?
- Optimal classification confidence threshold for default settings?
- Should new project creation require user confirmation or happen automatically?
- How to handle dictations that span multiple topics?
- Should we support manual drag-and-drop reorganization of droplets?
- What is the maximum number of droplets per project before pagination is needed?
- Should users be able to export/import their projects and droplets?
