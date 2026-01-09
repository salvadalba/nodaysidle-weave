# ARD

# Architecture Requirements Document

## 🧱 System Overview

Weave is a native macOS companion application that monitors the system clipboard for Super Whisper Pro dictations, performs real-time semantic topic classification using on-device CoreML, and automatically routes content into topical project columns with fluid glass UI animations.

## 🏗 Architecture Style

Event-driven reactive architecture with Combine framework for clipboard monitoring and SwiftUI for declarative UI rendering

## 🎨 Frontend Architecture

- **Framework:** SwiftUI with .ultraThinMaterial glass morphism design system
- **State Management:** Combine publishers with @StateObject and @Observable for view state, SwiftData @Model for persistent state
- **Routing:** Single-window macOS app with sheet-based navigation for project/topic settings
- **Build Tooling:** Xcode project with native Swift Package Manager for dependencies

## 🧠 Backend Architecture

- **Approach:** Local-only event processing with no server components
- **API Style:** Internal service layer via Combine publishers, no external APIs
- **Services:**
- ClipboardListenerService: NSPasteboard monitoring via Combine
- ClassificationService: CoreML + NaturalLanguage zero-shot topic classification
- DropletRoutingService: Maps classified topics to project columns
- PersistenceService: SwiftData CRUD operations for notes and projects

## 🗄 Data Layer

- **Primary Store:** SwiftData with @Model-persistent classes for Project and Droplet entities
- **Relationships:** One-to-many: Project has many Droplets, many-to-one: Droplet belongs to one Project
- **Migrations:** SwiftData automatic schema migrations with versioned ModelContainer

## ☁️ Infrastructure

- **Hosting:** Native macOS app bundle (.app) distributed locally or via Mac App Store
- **Scaling Strategy:** Single-user local application, no horizontal scaling required
- **CI/CD:** Xcode Cloud or GitHub Actions for macOS build automation and test execution

## ⚖️ Key Trade-offs

- macOS-only platform limits market reach but enables native performance and deep system integration
- On-device only classification ensures privacy but constrains model accuracy vs cloud alternatives
- Clipboard polling approach enables Super Whisper integration but depends on detectable pasteboard events
- SwiftData simplifies persistence but requires macOS 14+ limiting install base

## 📐 Non-Functional Requirements

- Sub-second latency for clipboard event detection and topic classification
- 60fps SwiftUI animations for fluid droplet transitions
- Memory footprint < 100MB during idle clipboard monitoring
- CPU usage < 5% during background clipboard polling
- Zero network dependency for full offline functionality
- Privacy-first: all data persisted locally without telemetry or analytics
