# PRD

# Weave

## 🎯 Product Vision

A native macOS companion brain for Super Whisper Pro that automatically transforms continuous voice streams into visually organized, topical workspaces through retroactive context threading—eliminating manual sorting of dictations.

## ❓ Problem Statement

Super Whisper Pro users capture continuous voice dictations that often span multiple topics and contexts. Manually sorting, organizing, and categorizing these monolithic text blocks into separate projects or notes is tedious, time-consuming, and disrupts the flow of continuous capture. Users need an intelligent layer that automatically detects semantic shifts and routes content to the right place without manual intervention.

## 🎯 Goals

- Automatically detect semantic topic shifts in continuous incoming text streams
- Visually split monolithic dictations into separate topical 'droplets' that route to project columns
- Provide real-time, zero-shot on-device text classification without network dependency
- Deliver a fluid glass UI with translucent panels and liquid physics animations
- Maintain local-first privacy with no server or network requirements
- Seamlessly integrate with Super Whisper Pro via system clipboard monitoring

## 🚫 Non-Goals

- Cross-platform support (iOS, iPadOS, Windows, web)
- Cloud sync or server-side processing
- Manual transcription or audio recording (delegates to Super Whisper Pro)
- Collaborative features or sharing capabilities
- Advanced text editing or word processing features
- Plugin system or third-party extensions

## 👥 Target Users

- Power users of Super Whisper Pro who capture continuous voice dictations
- Developers and knowledge workers who use voice for capturing bug reports, ideas, and task lists
- Mac-native users who prioritize privacy and local-first workflows
- Users who multitask by dictating across multiple contexts without pausing

## 🧩 Core Features

- Clipboard listener: Combine-based monitoring of NSPasteboard for Super Whisper Pro output
- Semantic topic detection: Real-time zero-shot classification using CoreML and NaturalLanguage framework
- Retroactive threading: Automatic splitting of monologues into separate 'droplets' based on detected topics
- Project columns: Visual workspaces where droplets route automatically based on topic classification
- Fluid glass UI: SwiftUI interface with .ultraThinMaterial and matchedGeometryEffect for translucent, animated panels
- SwiftData persistence: Local storage of threaded notes with persistent relationships
- Topic management: Create, rename, and delete project columns with associated topic keywords
- Droplet visual feedback: Animated 'flying' transitions as content routes to columns

## ⚙️ Non-Functional Requirements

- On-device processing with zero network dependency
- Real-time text classification with sub-second latency
- Native macOS performance with 60fps animations
- Privacy-first: all data stored locally, no telemetry
- Memory-efficient clipboard monitoring without impacting system performance
- macOS 14+ compatibility for latest SwiftUI and SwiftData features

## 📊 Success Metrics

- Accuracy rate of semantic topic detection (>85% correct routing)
- Average time saved per dictation session compared to manual sorting
- User-reported reduction in cognitive load during continuous capture
- System resource usage (CPU/memory) during clipboard monitoring
- User retention and daily active usage of automatic threading feature

## 📌 Assumptions

- Super Whisper Pro outputs dictations to system clipboard with detectable events
- Users speak primarily in English for NaturalLanguage framework accuracy
- Topic shifts occur with clear semantic boundaries detectable via text analysis
- Users have macOS 14+ and compatible hardware for CoreML inference
- Single-user usage scenario without collaboration requirements

## ❓ Open Questions

- What is the minimum text length required for accurate semantic shift detection?
- How should Weave handle ambiguous text that could belong to multiple topics?
- Should users be able to manually override automatic routing decisions?
- What is the maximum number of project columns before UI becomes cluttered?
- How should Weave behave when Super Whisper Pro is not actively running?
