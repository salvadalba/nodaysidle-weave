//
//  Logging.swift
//  Weave
//
//  OSLog infrastructure with categories for each service module.
//

import Foundation
import os.log

/// Centralized logging utility for Weave app
enum Log {
    /// Subsystem identifier for all Weave logs
    private static let subsystem = "com.weave.app"
    
    // MARK: - Log Categories
    
    /// General app lifecycle and initialization logs
    static let app = Logger(subsystem: subsystem, category: "App")
    
    /// Clipboard listener service logs
    static let clipboard = Logger(subsystem: subsystem, category: "ClipboardListener")
    
    /// Classification service logs
    static let classification = Logger(subsystem: subsystem, category: "ClassificationService")
    
    /// Persistence service logs
    static let persistence = Logger(subsystem: subsystem, category: "PersistenceService")
    
    /// Droplet routing service logs
    static let routing = Logger(subsystem: subsystem, category: "DropletRouting")
    
    /// Animation service logs
    static let animation = Logger(subsystem: subsystem, category: "Animation")
    
    /// UI-related logs
    static let ui = Logger(subsystem: subsystem, category: "UI")
}

// MARK: - Convenience Extensions

extension Logger {
    /// Log an operation with timing
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - block: The operation to time
    /// - Returns: The result of the operation
    func timed<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            self.debug("\(operation) completed in \(String(format: "%.2f", elapsed))ms")
        }
        return try block()
    }
    
    /// Log an async operation with timing
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - block: The async operation to time
    /// - Returns: The result of the operation
    func timedAsync<T>(_ operation: String, _ block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            self.debug("\(operation) completed in \(String(format: "%.2f", elapsed))ms")
        }
        return try await block()
    }
}
