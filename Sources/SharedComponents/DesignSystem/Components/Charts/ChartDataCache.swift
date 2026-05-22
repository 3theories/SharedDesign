import Foundation
import SwiftUI

// MARK: - ChartDataCache

/// Thread-safe actor for caching chart data with configurable TTL and memory management
@MainActor
public final class ChartDataCache: ObservableObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(maxEntries: Int = 100, memoryWarningThreshold: Int = 80) {
        self.maxEntries = maxEntries
        self.memoryWarningThreshold = memoryWarningThreshold

        // Setup memory pressure monitoring
        self.setupMemoryPressureMonitoring()

        // Setup periodic cleanup
        self.setupPeriodicCleanup()
    }

    // MARK: Public

    // MARK: - Types

    public struct CacheEntry<T> {
        let data: T
        let timestamp: Date
        let ttl: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(self.timestamp) > self.ttl
        }
    }

    public enum CachePolicy {
        case shortTerm // 30 seconds - for real-time data
        case standard // 5 minutes - for standard charts
        case longTerm // 30 minutes - for historical data
        case persistent // 24 hours - for stable metrics
        case custom(TimeInterval)

        // MARK: Internal

        var ttl: TimeInterval {
            switch self {
            case .shortTerm: 30
            case .standard: 300
            case .longTerm: 1800
            case .persistent: 86400
            case let .custom(interval): interval
            }
        }
    }

    public struct CacheStats {
        public var hitCount: Int = 0
        public var missCount: Int = 0
        public var totalRequests: Int = 0
        public var currentSize: Int = 0
        public var evictions: Int = 0

        public var hitRate: Double {
            guard self.totalRequests > 0 else {
                return 0
            }
            return Double(self.hitCount) / Double(self.totalRequests)
        }
    }

    @Published public private(set) var cacheStats = CacheStats()

    // MARK: - Public Methods

    /// Store data in cache with specified policy
    public func store(_ data: some Any, forKey key: String, policy: CachePolicy = .standard) {
        let entry = CacheEntry(data: data, timestamp: Date(), ttl: policy.ttl)

        self.cache[key] = entry
        self.accessTimes[key] = Date()

        self.updateStats(size: self.cache.count)

        // Check if we need to evict entries
        if self.cache.count > self.maxEntries {
            self.evictOldestEntries()
        }
    }

    /// Retrieve data from cache
    public func retrieve<T>(_ type: T.Type, forKey key: String) -> T? {
        self.cacheStats.totalRequests += 1

        guard let entry = cache[key] as? CacheEntry<T> else {
            self.cacheStats.missCount += 1
            return nil
        }

        // Check if entry is expired
        if entry.isExpired {
            self.remove(key)
            self.cacheStats.missCount += 1
            return nil
        }

        // Update access time for LRU
        self.accessTimes[key] = Date()
        self.cacheStats.hitCount += 1

        return entry.data
    }

    /// Remove specific entry
    public func remove(_ key: String) {
        self.cache.removeValue(forKey: key)
        self.accessTimes.removeValue(forKey: key)
        self.updateStats(size: self.cache.count)
    }

    /// Clear all cached data
    public func clearAll() {
        let oldSize = self.cache.count
        self.cache.removeAll()
        self.accessTimes.removeAll()

        self.cacheStats.evictions += oldSize
        self.updateStats(size: 0)
    }

    /// Clear expired entries manually
    public func clearExpired() {
        let expiredKeys = self.cache.compactMap { key, value -> String? in
            if let entry = value as? CacheEntry<Any>,
               entry.isExpired {
                return key
            }
            return nil
        }

        for key in expiredKeys {
            self.remove(key)
        }

        self.cacheStats.evictions += expiredKeys.count
    }

    /// Check if key exists and is not expired
    public func contains(_ key: String) -> Bool {
        guard let entry = cache[key] else {
            return false
        }

        // Use type-erased check for expiration
        let mirror = Mirror(reflecting: entry)
        if let timestampProperty = mirror.children.first(where: { $0.label == "timestamp" })?.value as? Date,
           let ttlProperty = mirror.children.first(where: { $0.label == "ttl" })?.value as? TimeInterval {
            return Date().timeIntervalSince(timestampProperty) <= ttlProperty
        }

        return true
    }

    /// Get cache size information
    public func getCacheInfo() -> (count: Int, hitRate: Double, totalRequests: Int) {
        (self.cache.count, self.cacheStats.hitRate, self.cacheStats.totalRequests)
    }

    // MARK: Private

    private var cache: [String: Any] = [:]
    private var accessTimes: [String: Date] = [:]
    private let maxEntries: Int
    private let memoryWarningThreshold: Int

    // MARK: - Private Methods

    private func updateStats(size: Int) {
        self.cacheStats.currentSize = size
    }

    private func evictOldestEntries() {
        let sortedByAccess = self.accessTimes.sorted { $0.value < $1.value }
        let entriesToEvict = sortedByAccess.prefix(self.cache.count - self.maxEntries + 10) // Keep some buffer

        for (key, _) in entriesToEvict {
            self.remove(key)
        }

        self.cacheStats.evictions += entriesToEvict.count
    }

    private func setupMemoryPressureMonitoring() {
        #if os(iOS)
            NotificationCenter.default.addObserver(
                forName: UIApplication.didReceiveMemoryWarningNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handleMemoryPressure()
                }
            }
        #endif
    }

    private func handleMemoryPressure() {
        // Clear half the cache on memory pressure
        guard !self.cache.isEmpty else {
            return
        }

        let targetSize = min(cache.count, max(10, self.cache.count / 2))
        let itemsToEvict = self.cache.count - targetSize

        // Only evict if there are items to evict
        guard itemsToEvict > 0 else {
            return
        }

        let sortedByAccess = self.accessTimes.sorted { $0.value < $1.value }
        let entriesToEvict = sortedByAccess.prefix(itemsToEvict)

        for (key, _) in entriesToEvict {
            self.remove(key)
        }

        self.cacheStats.evictions += entriesToEvict.count
    }

    private func setupPeriodicCleanup() {
        // Clean up expired entries every 2 minutes
        Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.clearExpired()
            }
        }
    }
}

// MARK: - Convenience Methods

extension ChartDataCache {
    /// Cache aggregated stats
    public func cacheStats(_ stats: some Any, for period: String, type: String) {
        self.store(stats, forKey: "stats_\(type)_\(period)", policy: .standard)
    }

    /// Retrieve aggregated stats
    public func getStats<T>(_ type: T.Type, for period: String, statsType: String) -> T? {
        self.retrieve(type, forKey: "stats_\(statsType)_\(period)")
    }
}

// MARK: - Cache Key Helpers

extension ChartDataCache {
    /// Generate a standardized cache key
    public static func key(for type: String, period: String, userId: String? = nil) -> String {
        if let userId {
            "\(type)_\(period)_\(userId)"
        } else {
            "\(type)_\(period)"
        }
    }

    /// Generate a cache key with hash for complex parameters
    public static func key(for type: String, parameters: [String: Any]) -> String {
        let sortedParams = parameters.keys.sorted().compactMap { key -> String? in
            if let value = parameters[key] {
                return "\(key)=\(value)"
            }
            return nil
        }.joined(separator: "&")

        return "\(type)_\(sortedParams.hash)"
    }
}
