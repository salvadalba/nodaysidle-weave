//
//  DropletAnimationService.swift
//  Weave
//
//  Coordinates matchedGeometryEffect animations for droplet flight paths.
//

import Foundation
import SwiftUI
import Combine

/// Service for coordinating droplet animations
@Observable
final class DropletAnimationService {
    // MARK: - Configuration
    
    /// Animation duration in seconds
    var animationDuration: TimeInterval = 0.3
    
    /// Spring response for animations
    var springResponse: Double = 0.4
    
    /// Spring damping fraction
    var springDamping: Double = 0.8
    
    // MARK: - State
    
    /// Currently animating droplet IDs
    private(set) var animatingDroplets: Set<UUID> = []
    
    /// Source positions for animating droplets
    private var sourcePositions: [UUID: CGRect] = [:]
    
    /// Target positions for animating droplets
    private var targetPositions: [UUID: CGRect] = [:]
    
    // MARK: - Publishers
    
    /// Publisher for animation state changes
    var animationStatePublisher: AnyPublisher<AnimationState, Never> {
        animationStateSubject.eraseToAnyPublisher()
    }
    
    private let animationStateSubject = PassthroughSubject<AnimationState, Never>()
    
    // MARK: - Animation State
    
    enum AnimationState {
        case started(dropletId: UUID)
        case completed(dropletId: UUID)
        case cancelled(dropletId: UUID)
    }
    
    // MARK: - Public Methods
    
    /// Start animating a droplet from source to destination
    /// - Parameters:
    ///   - droplet: The droplet to animate
    ///   - from: Source rectangle in window coordinates
    ///   - to: Destination rectangle in window coordinates
    func animate(droplet: Droplet, from: CGRect, to: CGRect) {
        let dropletId = droplet.id
        
        // Store positions
        sourcePositions[dropletId] = from
        targetPositions[dropletId] = to
        animatingDroplets.insert(dropletId)
        
        // Emit started state
        animationStateSubject.send(.started(dropletId: dropletId))
        
        Log.animation.debug("Started animation for droplet \(dropletId)")
        
        // Schedule completion
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            self?.completeAnimation(for: dropletId)
        }
    }
    
    /// Cancel an ongoing animation
    func cancelAnimation(for dropletId: UUID) {
        guard animatingDroplets.contains(dropletId) else { return }
        
        cleanup(dropletId: dropletId)
        animationStateSubject.send(.cancelled(dropletId: dropletId))
        
        Log.animation.debug("Cancelled animation for droplet \(dropletId)")
    }
    
    /// Check if a droplet is currently animating
    func isAnimating(_ droplet: Droplet) -> Bool {
        animatingDroplets.contains(droplet.id)
    }
    
    /// Get the source position for an animating droplet
    func sourcePosition(for dropletId: UUID) -> CGRect? {
        sourcePositions[dropletId]
    }
    
    /// Get the target position for an animating droplet
    func targetPosition(for dropletId: UUID) -> CGRect? {
        targetPositions[dropletId]
    }
    
    /// Get the spring animation to use
    var springAnimation: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }
    
    // MARK: - Private Methods
    
    private func completeAnimation(for dropletId: UUID) {
        guard animatingDroplets.contains(dropletId) else { return }
        
        cleanup(dropletId: dropletId)
        animationStateSubject.send(.completed(dropletId: dropletId))
        
        Log.animation.debug("Completed animation for droplet \(dropletId)")
    }
    
    private func cleanup(dropletId: UUID) {
        animatingDroplets.remove(dropletId)
        sourcePositions.removeValue(forKey: dropletId)
        targetPositions.removeValue(forKey: dropletId)
    }
}

// MARK: - Animation Modifier

/// View modifier for droplet insertion animation
struct DropletInsertionModifier: ViewModifier {
    let isNew: Bool
    let namespace: Namespace.ID
    let dropletId: UUID
    
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)
            .offset(y: appeared ? 0 : -20)
            .matchedGeometryEffect(
                id: dropletId,
                in: namespace,
                isSource: true
            )
            .onAppear {
                if isNew {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        appeared = true
                    }
                } else {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Apply droplet insertion animation
    func dropletInsertion(isNew: Bool, namespace: Namespace.ID, dropletId: UUID) -> some View {
        modifier(DropletInsertionModifier(isNew: isNew, namespace: namespace, dropletId: dropletId))
    }
}

// MARK: - Flying Droplet View

/// A view that animates a droplet flying to its destination
struct FlyingDropletView: View {
    let content: String
    let sourceRect: CGRect
    let targetRect: CGRect
    let onComplete: () -> Void
    
    @State private var progress: CGFloat = 0
    
    var body: some View {
        // Droplet content
        Text(content)
            .font(.subheadline)
            .lineLimit(2)
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .position(currentPosition)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    progress = 1
                }
                
                // Complete after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onComplete()
                }
            }
    }
    
    private var currentPosition: CGPoint {
        let startX = sourceRect.midX
        let startY = sourceRect.midY
        let endX = targetRect.midX
        let endY = targetRect.midY
        
        // Curved path with arc
        let arcHeight: CGFloat = -50
        let currentX = startX + (endX - startX) * progress
        let currentY = startY + (endY - startY) * progress + arcHeight * sin(progress * .pi)
        
        return CGPoint(x: currentX, y: currentY)
    }
}
