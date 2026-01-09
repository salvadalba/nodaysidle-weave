//
//  ClipboardListenerService.swift
//  Weave
//
//  Monitors NSPasteboard for Super Whisper Pro dictation output.
//

import Foundation
import AppKit
import Combine
import SwiftUI

/// Errors that can occur during clipboard monitoring
enum ClipboardError: Error, LocalizedError {
    case pasteboardReadFailure
    case emptyContent
    case nonTextContent
    case contentTooShort
    
    var errorDescription: String? {
        switch self {
        case .pasteboardReadFailure:
            return "Failed to read from system pasteboard"
        case .emptyContent:
            return "Clipboard content is empty"
        case .nonTextContent:
            return "Clipboard does not contain text content"
        case .contentTooShort:
            return "Clipboard content is too short (minimum 3 characters)"
        }
    }
}

/// Service that monitors the system clipboard for Super Whisper Pro dictation output
@Observable
final class ClipboardListenerService {
    // MARK: - Published State
    
    /// Whether clipboard monitoring is currently active
    private(set) var isMonitoring: Bool = false
    
    /// Last captured clipboard content
    private(set) var lastContent: String?
    
    /// Count of clipboard events captured
    private(set) var eventCount: Int = 0
    
    // MARK: - Configuration
    
    /// Polling interval in seconds (default: 250ms)
    var pollingInterval: TimeInterval = 0.25
    
    /// Debounce duration in seconds for rapid events
    var debounceDuration: TimeInterval = 0.5
    
    /// Minimum character count for valid content
    var minimumCharacterCount: Int = 3
    
    // MARK: - Publishers
    
    /// Publisher that emits validated clipboard content
    var clipboardPublisher: AnyPublisher<String, Never> {
        clipboardSubject
            .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    /// Raw clipboard events without debouncing (for rapid event detection)
    var rawClipboardPublisher: AnyPublisher<String, Never> {
        clipboardSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    
    private let clipboardSubject = PassthroughSubject<String, Never>()
    private var pollingTimer: Timer?
    private var lastChangeCount: Int = 0
    private var previousContent: String?
    private var rapidEventCount: Int = 0
    private var rapidEventTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        Log.clipboard.info("ClipboardListenerService initialized")
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring the system clipboard for changes
    func startMonitoring() {
        guard !isMonitoring else {
            Log.clipboard.warning("Clipboard monitoring already active")
            return
        }
        
        isMonitoring = true
        lastChangeCount = NSPasteboard.general.changeCount
        
        // Create polling timer
        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: pollingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkClipboard()
        }
        
        // Add to run loop for reliable timing
        if let timer = pollingTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        Log.clipboard.info("Started clipboard monitoring at \(self.pollingInterval)s intervals")
    }
    
    /// Stop monitoring the system clipboard
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        pollingTimer?.invalidate()
        pollingTimer = nil
        rapidEventTimer?.invalidate()
        rapidEventTimer = nil
        isMonitoring = false
        
        Log.clipboard.info("Stopped clipboard monitoring")
    }
    
    /// Update the polling interval (restarts monitoring if active)
    func setPollingInterval(_ interval: TimeInterval) {
        let wasMonitoring = isMonitoring
        
        if wasMonitoring {
            stopMonitoring()
        }
        
        pollingInterval = max(0.1, min(0.5, interval)) // Clamp between 100ms and 500ms
        
        if wasMonitoring {
            startMonitoring()
        }
        
        Log.clipboard.info("Polling interval updated to \(self.pollingInterval)s")
    }
    
    // MARK: - Private Methods
    
    /// Check the clipboard for new content
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        // Check if clipboard has changed
        guard currentChangeCount != lastChangeCount else {
            return
        }
        
        lastChangeCount = currentChangeCount
        
        // Validate and extract clipboard content
        do {
            let content = try validateAndExtractContent(from: pasteboard)
            
            // Check for duplicate content
            guard content != previousContent else {
                Log.clipboard.debug("Duplicate clipboard content ignored")
                return
            }
            
            previousContent = content
            lastContent = content
            eventCount += 1
            
            // Track rapid events for batching mode
            trackRapidEvent()
            
            // Emit to publisher
            clipboardSubject.send(content)
            
            Log.clipboard.info("Captured clipboard content: \(content.prefix(50))...")
            
        } catch let error as ClipboardError {
            Log.clipboard.debug("Clipboard validation failed: \(error.localizedDescription)")
        } catch {
            Log.clipboard.error("Unexpected clipboard error: \(error.localizedDescription)")
        }
    }
    
    /// Validate and extract text content from pasteboard
    private func validateAndExtractContent(from pasteboard: NSPasteboard) throws -> String {
        // Check for text content
        guard let content = pasteboard.string(forType: .string) else {
            throw ClipboardError.nonTextContent
        }
        
        // Trim whitespace
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for empty content
        guard !trimmedContent.isEmpty else {
            throw ClipboardError.emptyContent
        }
        
        // Check minimum length
        guard trimmedContent.count >= minimumCharacterCount else {
            throw ClipboardError.contentTooShort
        }
        
        return trimmedContent
    }
    
    /// Track rapid clipboard events for batching mode
    private func trackRapidEvent() {
        rapidEventCount += 1
        
        // Reset count after 2 seconds
        rapidEventTimer?.invalidate()
        rapidEventTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            if let count = self?.rapidEventCount, count > 3 {
                Log.clipboard.info("Rapid event mode: \(count) events in 2 seconds")
            }
            self?.rapidEventCount = 0
        }
    }
}

// MARK: - Environment Key

private struct ClipboardListenerServiceKey: EnvironmentKey {
    static let defaultValue = ClipboardListenerService()
}

extension EnvironmentValues {
    var clipboardListener: ClipboardListenerService {
        get { self[ClipboardListenerServiceKey.self] }
        set { self[ClipboardListenerServiceKey.self] = newValue }
    }
}
