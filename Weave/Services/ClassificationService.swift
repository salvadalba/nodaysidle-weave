//
//  ClassificationService.swift
//  Weave
//
//  On-device zero-shot topic classification using CoreML and NaturalLanguage framework.
//

import Foundation
import NaturalLanguage
import Combine

/// Result of topic classification
struct ClassificationResult {
    /// The classified topic name
    let topic: String
    
    /// Confidence score (0.0 - 1.0)
    let confidence: Double
    
    /// When the classification was performed
    let timestamp: Date
    
    /// Whether this is a high-confidence classification
    var isHighConfidence: Bool {
        confidence >= 0.6
    }
}

/// Errors that can occur during classification
enum ClassificationError: Error, LocalizedError {
    case textTooShort
    case noTopicMatch
    case modelLoadFailure(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .textTooShort:
            return "Text is too short for classification (minimum 3 characters)"
        case .noTopicMatch:
            return "No matching topic found with sufficient confidence"
        case .modelLoadFailure(let reason):
            return "Failed to load classification model: \(reason)"
        }
    }
}

/// Service for on-device text classification using NaturalLanguage framework
@Observable
final class ClassificationService {
    /// Minimum confidence threshold for routing to existing projects
    var minimumConfidence: Double = 0.6
    
    /// Cache for classification results (keyed by text hash)
    private var cache: [Int: ClassificationResult] = [:]
    
    /// Maximum cache size before purging
    private let maxCacheEntries = 1000
    
    /// NLP embedding model for semantic similarity
    private var embeddingModel: NLEmbedding?
    
    /// Sentence embedding for topic matching
    private let sentenceEmbedding: NLEmbedding?
    
    init() {
        // Load sentence embedding for semantic similarity
        self.sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english)
        
        if sentenceEmbedding == nil {
            Log.classification.warning("Sentence embedding not available, falling back to word embedding")
        }
        
        self.embeddingModel = NLEmbedding.wordEmbedding(for: .english)
        
        Log.classification.info("ClassificationService initialized")
    }
    
    /// Classify text against known topics
    /// - Parameters:
    ///   - text: The text to classify
    ///   - knownTopics: List of known topic names to match against
    /// - Returns: Classification result with topic and confidence
    /// - Throws: ClassificationError if classification fails
    func classify(_ text: String, knownTopics: [String]) throws -> ClassificationResult {
        // Validate input
        guard text.count >= 3 else {
            Log.classification.warning("Text too short for classification: \(text.count) chars")
            throw ClassificationError.textTooShort
        }
        
        // Check cache
        let cacheKey = text.hashValue
        if let cached = cache[cacheKey] {
            Log.classification.debug("Cache hit for classification")
            return cached
        }
        
        // If no known topics, return uncategorized
        guard !knownTopics.isEmpty else {
            let result = ClassificationResult(
                topic: "Uncategorized",
                confidence: 0.0,
                timestamp: Date()
            )
            cacheResult(result, for: cacheKey)
            return result
        }
        
        // Perform semantic classification
        let result = performSemanticClassification(text: text, topics: knownTopics)
        
        // Check if confidence meets threshold
        if result.confidence < self.minimumConfidence {
            Log.classification.info("Classification confidence \(result.confidence) below threshold \(self.minimumConfidence)")
            throw ClassificationError.noTopicMatch
        }
        
        // Cache and return result
        cacheResult(result, for: cacheKey)
        Log.classification.info("Classified as '\(result.topic)' with confidence \(result.confidence)")
        
        return result
    }
    
    /// Classify text and return best match or uncategorized on failure
    /// - Parameters:
    ///   - text: The text to classify
    ///   - knownTopics: List of known topic names
    /// - Returns: Classification result (never throws)
    func classifyWithFallback(_ text: String, knownTopics: [String]) -> ClassificationResult {
        do {
            return try classify(text, knownTopics: knownTopics)
        } catch {
            Log.classification.info("Classification fallback to Uncategorized: \(error.localizedDescription)")
            return ClassificationResult(
                topic: "Uncategorized",
                confidence: 0.0,
                timestamp: Date()
            )
        }
    }
    
    /// Clear the classification cache
    func clearCache() {
        cache.removeAll()
        Log.classification.info("Classification cache cleared")
    }
    
    // MARK: - Private Methods
    
    /// Perform semantic similarity-based classification
    private func performSemanticClassification(text: String, topics: [String]) -> ClassificationResult {
        var bestTopic = "Uncategorized"
        var bestScore: Double = 0.0
        
        // Tokenize and extract key terms from input text
        let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
        tagger.string = text.lowercased()
        
        var inputTerms: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameTypeOrLexicalClass) { tag, range in
            if let tag = tag {
                // Include nouns, verbs, and adjectives
                if tag == .noun || tag == .verb || tag == .adjective {
                    let word = String(text[range]).lowercased()
                    if word.count > 2 {
                        inputTerms.append(word)
                    }
                }
            }
            return true
        }
        
        // Calculate similarity score for each topic
        for topic in topics {
            let topicLower = topic.lowercased()
            var score: Double = 0.0
            
            // Direct keyword match (highest weight)
            if text.lowercased().contains(topicLower) {
                score += 0.6
            }
            
            // Semantic similarity using embeddings
            if let embedding = embeddingModel {
                for term in inputTerms {
                    let distance = embedding.distance(between: term, and: topicLower)
                    // Convert distance to similarity (smaller distance = higher similarity)
                    let similarity = max(0, 1.0 - distance)
                    score += similarity * 0.1
                }
            }
            
            // Use sentence embedding if available
            if let sentenceEmbed = sentenceEmbedding {
                let topicSentence = "This is about \(topic)"
                let distance = sentenceEmbed.distance(between: text, and: topicSentence)
                let similarity = max(0, 1.0 - distance)
                score += similarity * 0.3
            }
            
            // Normalize score
            score = min(1.0, score)
            
            if score > bestScore {
                bestScore = score
                bestTopic = topic
            }
        }
        
        return ClassificationResult(
            topic: bestTopic,
            confidence: bestScore,
            timestamp: Date()
        )
    }
    
    /// Cache a classification result, purging if necessary
    private func cacheResult(_ result: ClassificationResult, for key: Int) {
        // Purge cache if too large
        let maxEntries = self.maxCacheEntries
        if cache.count >= maxEntries {
            Log.classification.info("Purging classification cache (exceeded \(maxEntries) entries)")
            // Remove oldest half of entries
            let keysToRemove = Array(cache.keys.prefix(cache.count / 2))
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
        
        cache[key] = result
    }
}

// MARK: - Topic Suggestion

extension ClassificationService {
    /// Suggest a topic name based on text content
    /// - Parameter text: The text to analyze
    /// - Returns: Suggested topic name
    func suggestTopic(from text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
        tagger.string = text
        
        var nouns: [String: Int] = [:]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameTypeOrLexicalClass) { tag, range in
            if tag == .noun {
                let word = String(text[range]).lowercased()
                if word.count > 3 {
                    nouns[word, default: 0] += 1
                }
            }
            return true
        }
        
        // Return the most frequent noun, capitalized
        if let topNoun = nouns.max(by: { $0.value < $1.value })?.key {
            return topNoun.capitalized
        }
        
        return "Uncategorized"
    }
}
