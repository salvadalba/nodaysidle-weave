ROLE: Expert Swift/macOS Engineer

GOAL: Create Xcode project with SwiftData schema and CoreML classification service

CONTEXT: Set up the Xcode project structure with SwiftData models for Projects/Droplets and CoreML classification service using NaturalLanguage framework for on-device zero-shot topic classification.

FILES TO CREATE:

- Weave/WeaveApp.swift
- Weave/Models/Project.swift
- Weave/Models/Droplet.swift
- Weave/Services/ClassificationService.swift
- Weave/Utilities/Logging.swift

FILES TO MODIFY:
_None_

DETAILED STEPS:

1. Create Xcode project as macOS app targeting macOS 14.0+, bundle ID com.weave.app
2. Create Project and Droplet @Model classes with one-to-many relationship
3. Configure SwiftData ModelContainer in WeaveApp with both models
4. Implement ClassificationService using NLTagger for zero-shot classification with confidence scoring
5. Create OSLog infrastructure with subsystem 'com.weave.app' and categories

VALIDATION:
xcodebuild -scheme Weave -destination 'platform=macOS' build

```

---

## Clipboard Monitoring with Combine and NSPasteboard

**Context**
Build a clipboard monitoring service that polls NSPasteboard at 250ms intervals to detect Super Whisper Pro dictation output, with debouncing and validation.

### Universal Agent Prompt
```

ROLE: Expert Swift/Combine Engineer

GOAL: Implement NSPasteboard clipboard listener with Combine publishers

CONTEXT: Build a clipboard monitoring service that polls NSPasteboard at 250ms intervals to detect Super Whisper Pro dictation output, with debouncing and validation.

FILES TO CREATE:

- Weave/Services/ClipboardListenerService.swift

FILES TO MODIFY:
_None_

DETAILED STEPS:

1. Create ClipboardListenerService with clipboardPublisher: AnyPublisher<String, Never>
2. Implement NSTimer-based polling at 250ms intervals reading NSPasteboard.general.string(forType: .string)
3. Add change detection to only emit new content (not duplicates)
4. Implement debounce operator for rapid events with batching mode
5. Add validation: reject empty strings, content < 3 chars, non-text content

VALIDATION:
xcodebuild -scheme Weave -destination 'platform=macOS' build

```

---

## Persistence and Droplet Routing Services

**Context**
Build SwiftData CRUD operations for Projects/Droplets and routing logic that maps classification results to existing projects or creates new ones automatically.

### Universal Agent Prompt
```

ROLE: Expert Swift/SwiftData Engineer

GOAL: Create persistence service with CRUD operations and droplet routing logic

CONTEXT: Build SwiftData CRUD operations for Projects/Droplets and routing logic that maps classification results to existing projects or creates new ones automatically.

FILES TO CREATE:

- Weave/Services/PersistenceService.swift
- Weave/Services/DropletRoutingService.swift

FILES TO MODIFY:
_None_

DETAILED STEPS:

1. Create PersistenceService with ModelContainer, createProject/createDroplet/fetchProjects/fetchDroplets/delete methods
2. Implement validation: 1-50 char names, duplicate check, project existence validation
3. Use #Predicate for indexed queries on project_id and timestamp for sub-50ms retrieval
4. Create DropletRoutingService with route() method mapping classifications to projects by topicKeywords
5. Implement shouldCreateNewTopic() for auto-creating projects with random colors and auto-generated keywords

VALIDATION:
xcodebuild -scheme Weave -destination 'platform=macOS' build

```

---

## SwiftUI Layout with Project Columns and Fluid Glass Aesthetics

**Context**
Build the main UI with horizontal scrolling project columns displaying droplets, using .ultraThinMaterial for glass morphism effects and matchedGeometryEffect for animations.

### Universal Agent Prompt
```

ROLE: Expert SwiftUI Engineer

GOAL: Create SwiftUI interface with project columns and glass morphism styling

CONTEXT: Build the main UI with horizontal scrolling project columns displaying droplets, using .ultraThinMaterial for glass morphism effects and matchedGeometryEffect for animations.

FILES TO CREATE:

- Weave/Views/ContentView.swift
- Weave/Views/ProjectColumn.swift
- Weave/Views/DropletView.swift
- Weave/ViewModels/ContentViewModel.swift

FILES TO MODIFY:

- Weave/WeaveApp.swift

DETAILED STEPS:

1. Create ContentView with LazyHStack for horizontal project columns fetching from SwiftData
2. Build ProjectColumn component with LazyVStack for droplets, project name and color indicator
3. Create DropletView displaying content, timestamp, and confidence badge
4. Apply .background(.ultraThinMaterial) with 12px corner radius and shadow to columns and droplets
5. Set up @Namespace in ContentView for matchedGeometryEffect animations

VALIDATION:
xcodebuild -scheme Weave -destination 'platform=macOS' build

```

---

## Droplet Animation and Service Integration

**Context**
Implement matchedGeometryEffect animations for droplet flight paths, create DropletAnimationService, and wire the complete service chain from clipboard to UI.

### Universal Agent Prompt
```

ROLE: Expert Swift/Animation Engineer

GOAL: Implement droplet animations and integrate all services end-to-end

CONTEXT: Implement matchedGeometryEffect animations for droplet flight paths, create DropletAnimationService, and wire the complete service chain from clipboard to UI.

FILES TO CREATE:

- Weave/Services/DropletAnimationService.swift
- Weave/Views/SettingsView.swift

FILES TO MODIFY:

- Weave/ViewModels/ContentViewModel.swift
- Weave/Views/ContentView.swift

DETAILED STEPS:

1. Create DropletAnimationService with animate(droplet:from:to:) method and 0.3s duration
2. Implement matchedGeometryEffect with @Namespace passed to child views for shared coordinates
3. Animate droplet insertion with spring timing and curved flight path
4. Wire complete flow: ClipboardListener → ClassificationService → DropletRoutingService → PersistenceService → UI updates
5. Create SettingsView with project creation/editing, confidence threshold slider, and clipboard sensitivity controls

VALIDATION:
xcodebuild -scheme Weave -destination 'platform=macOS' build
