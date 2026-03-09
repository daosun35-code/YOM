import CoreLocation
import Foundation

/// Evaluates whether a user has met the unlock conditions for a memory point:
/// 1. Within `unlockRadiusM` of the target coordinate.
/// 2. Accumulated dwell time >= `requiredDwellSeconds`.
///
/// Dwell timer uses a **tolerant accumulation** strategy:
/// short GPS signal bounces (< `bounceToleranceSeconds`) do NOT reset the counter.
@MainActor
final class UnlockEvaluator: ObservableObject {
    @Published private(set) var isInRange = false
    @Published private(set) var isUnlocked = false
    @Published private(set) var dwellAccumulatedSeconds: TimeInterval = 0

    private let target: MemoryPoint
    private let requiredDwellSeconds: TimeInterval
    private let bounceToleranceSeconds: TimeInterval

    private var lastInRangeTimestamp: Date?
    private var lastOutOfRangeTimestamp: Date?

    init(
        target: MemoryPoint,
        requiredDwellSeconds: TimeInterval = 10,
        bounceToleranceSeconds: TimeInterval = 3
    ) {
        self.target = target
        self.requiredDwellSeconds = requiredDwellSeconds
        self.bounceToleranceSeconds = bounceToleranceSeconds
    }

    /// Call this each time a new user location sample arrives.
    func updateLocation(_ userCoordinate: CLLocationCoordinate2D) {
        guard !isUnlocked else { return }

        let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let targetLocation = CLLocation(latitude: target.coordinate.latitude, longitude: target.coordinate.longitude)
        let distance = userLocation.distance(from: targetLocation)
        let now = Date()

        if distance <= target.unlockRadiusM {
            handleInRange(at: now)
        } else {
            handleOutOfRange(at: now)
        }
    }

    /// Reset all state (e.g. when cancelling navigation).
    func reset() {
        isInRange = false
        isUnlocked = false
        dwellAccumulatedSeconds = 0
        lastInRangeTimestamp = nil
        lastOutOfRangeTimestamp = nil
    }

    /// Force unlock (for UI testing / debug bypass).
    func forceUnlock() {
        isUnlocked = true
        isInRange = true
    }

    // MARK: - Private

    private func handleInRange(at now: Date) {
        lastOutOfRangeTimestamp = nil

        if !isInRange {
            isInRange = true
            lastInRangeTimestamp = now
        }

        if let enteredAt = lastInRangeTimestamp {
            dwellAccumulatedSeconds = now.timeIntervalSince(enteredAt)
        }

        if dwellAccumulatedSeconds >= requiredDwellSeconds {
            isUnlocked = true
        }
    }

    private func handleOutOfRange(at now: Date) {
        if isInRange {
            // Start out-of-range timer — don't immediately reset
            if lastOutOfRangeTimestamp == nil {
                lastOutOfRangeTimestamp = now
            }

            if let exitedAt = lastOutOfRangeTimestamp,
               now.timeIntervalSince(exitedAt) >= bounceToleranceSeconds {
                // Exceeded bounce tolerance — genuine exit
                isInRange = false
                dwellAccumulatedSeconds = 0
                lastInRangeTimestamp = nil
                lastOutOfRangeTimestamp = nil
            }
            // Otherwise: within bounce tolerance, keep accumulating
        }
    }
}
