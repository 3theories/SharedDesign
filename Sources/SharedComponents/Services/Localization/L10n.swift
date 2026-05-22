import Foundation

enum L10n {
    // MARK: Internal

    static func string(
        _ keyAndValue: String.LocalizationValue,
        table: String? = nil,
        bundle: Bundle = .main,
        locale: Locale = .current,
        comment: StaticString? = nil
    ) -> String {
        let key = self.localizationKey(from: keyAndValue)
        let resolved = self.resolvedString(for: key, table: table, bundle: bundle)
        #if DEBUG
            self.assertResolved(resolved, key: key, defaultValue: nil, table: table)
        #endif
        _ = locale
        _ = comment
        return resolved
    }

    static func string(
        _ keyAndValue: String.LocalizationValue,
        defaultValue: String,
        table: String? = nil,
        bundle: Bundle = .main,
        locale: Locale = .current,
        comment: StaticString? = nil
    ) -> String {
        let key = self.localizationKey(from: keyAndValue)
        var foundInCatalog = false
        let resolved = self.resolvedString(
            for: key,
            table: table,
            bundle: bundle,
            defaultValue: defaultValue,
            foundInCatalog: &foundInCatalog
        )
        #if DEBUG
            if !foundInCatalog {
                self.assertResolved(resolved, key: key, defaultValue: defaultValue, table: table)
            }
        #endif
        _ = locale
        _ = comment
        return resolved
    }

    static func string(_ resource: LocalizedStringResource) -> String {
        let resolved = String(localized: resource)
        #if DEBUG
            self.assertGenericResolved(resolved, context: String(describing: resource))
        #endif
        return resolved
    }

    static func string(_ resource: LocalizedStringResource, locale: Locale = .current) -> String {
        let resolved = String(localized: resource)
        #if DEBUG
            self.assertGenericResolved(resolved, context: String(describing: resource))
        #endif
        _ = locale
        return resolved
    }

    static func format(
        _ keyAndValue: String.LocalizationValue,
        table: String? = nil,
        bundle: Bundle = .main,
        locale: Locale = .current,
        _ args: Any...
    ) -> String {
        let formatString = self.string(keyAndValue, table: table, bundle: bundle, locale: locale)
        let key = self.localizationKey(from: keyAndValue)
        return self.safeFormat(
            formatString,
            args: args,
            locale: locale,
            debugContext: "key=\(key) table=\(table ?? "Localizable")"
        )
    }

    // MARK: Private

    #if DEBUG
        private static let unresolvedSentinels: Set<String> = [
            "",
            "Title",
            "Subtitle",
            "Message"
        ]
        private static var reportedIssues = Set<String>()
        private static let reportLock = NSLock()

        private static func assertResolved(_ resolved: String, key: String, defaultValue: String?, table: String?) {
            let trimmed = resolved.trimmingCharacters(in: .whitespacesAndNewlines)
            let unresolved =
                self.unresolvedSentinels.contains(trimmed) ||
                trimmed == key ||
                (defaultValue != nil && trimmed == defaultValue)

            guard unresolved else {
                return
            }

            self.logOnce("[L10N_MISSING_KEY] key=\(key) table=\(table ?? "Localizable") resolved=\(resolved)")
        }

        private static func assertGenericResolved(_ resolved: String, context: String) {
            let trimmed = resolved.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = self.extractResourceKey(from: context)
            let unresolved =
                self.unresolvedSentinels.contains(trimmed) ||
                (key != nil && key == trimmed)

            guard unresolved else {
                return
            }

            self.logOnce("[L10N_MISSING_KEY] context=\(context) resolved=\(resolved)")
        }

        private static func extractResourceKey(from context: String) -> String? {
            let needle = "key: \""
            guard let start = context.range(of: needle)?.upperBound else {
                return nil
            }
            guard let end = context[start...].firstIndex(of: "\"") else {
                return nil
            }
            return String(context[start..<end])
        }

        private static func logOnce(_ message: String) {
            self.reportLock.lock()
            defer { reportLock.unlock() }
            guard self.reportedIssues.insert(message).inserted else {
                return
            }
            print(message)
        }
    #endif

    private static let formatSpecifierRegex = try? NSRegularExpression(
        pattern: "%(?!%)(?:(\\d+)\\$)?[\\-\\+ 0#]*(?:\\d+)?(?:\\.\\d+)?[hlLzjtq]*([@dDuUxXoOfeEgGaAcCsS])"
    )

    private static func safeFormat(
        _ format: String,
        args: [Any],
        locale: Locale,
        debugContext: String
    ) -> String {
        guard let regex = formatSpecifierRegex else {
            return format
        }

        let ns = format as NSString
        let matches = regex.matches(in: format, range: NSRange(location: 0, length: ns.length))
        if matches.isEmpty {
            return format
        }

        let hasPositional = matches.contains { $0.range(at: 1).location != NSNotFound }
        var nextSequentialIndex = 0
        var converted: [CVarArg] = []

        for match in matches {
            let argIndex: Int
            if let positional = substring(in: format, range: match.range(at: 1)), let p = Int(positional), p > 0 {
                argIndex = p - 1
            } else {
                argIndex = nextSequentialIndex
                nextSequentialIndex += 1
            }

            let specifier = self.substring(in: format, range: match.range(at: 2)) ?? "@"
            let arg = argIndex < args.count ? args[argIndex] : nil
            converted.append(self.convertArg(arg, for: specifier))
        }

        #if DEBUG
            let requiredArgCount: Int =
                if hasPositional {
                    matches.compactMap {
                        guard let positional = substring(in: format, range: $0.range(at: 1)),
                              let p = Int(positional) else {
                            return nil
                        }
                        return p
                    }.max() ?? converted.count
                } else {
                    converted.count
                }
            if args.count < requiredArgCount {
                self
                    .logOnce(
                        "[L10N_FORMAT_MISMATCH] Missing args context=\(debugContext) format=\(format) required=\(requiredArgCount) got=\(args.count)"
                    )
            }
        #endif

        return withVaList(converted) { pointer in
            NSString(format: format, locale: locale, arguments: pointer) as String
        }
    }

    private static func convertArg(_ arg: Any?, for specifier: String) -> CVarArg {
        let type = specifier.lowercased()
        if type == "@" {
            return NSString(string: String(describing: arg ?? ""))
        }

        if ["d", "i", "u", "x", "o", "c"].contains(type) {
            if let v = arg as? Int {
                return v
            }
            if let v = arg as? Int8 {
                return Int(v)
            }
            if let v = arg as? Int16 {
                return Int(v)
            }
            if let v = arg as? Int32 {
                return Int(v)
            }
            if let v = arg as? Int64 {
                return Int(v)
            }
            if let v = arg as? UInt {
                return Int(v)
            }
            if let v = arg as? UInt8 {
                return Int(v)
            }
            if let v = arg as? UInt16 {
                return Int(v)
            }
            if let v = arg as? UInt32 {
                return Int(v)
            }
            if let v = arg as? UInt64 {
                return Int(v)
            }
            if let v = arg as? Double {
                return Int(v)
            }
            if let v = arg as? Float {
                return Int(v)
            }
            if let v = arg as? CGFloat {
                return Int(v)
            }
            if let v = arg as? NSNumber {
                return v.intValue
            }
            if let s = arg as? String, let v = Int(s) {
                return v
            }
            return 0
        }

        if ["f", "e", "g", "a"].contains(type) {
            if let v = arg as? Double {
                return v
            }
            if let v = arg as? Float {
                return Double(v)
            }
            if let v = arg as? CGFloat {
                return Double(v)
            }
            if let v = arg as? Int {
                return Double(v)
            }
            if let v = arg as? NSNumber {
                return v.doubleValue
            }
            if let s = arg as? String, let v = Double(s) {
                return v
            }
            return 0.0
        }

        if type == "s" {
            return NSString(string: String(describing: arg ?? ""))
        }

        return NSString(string: String(describing: arg ?? ""))
    }

    private static func substring(in text: String, range: NSRange) -> String? {
        guard range.location != NSNotFound, let r = Range(range, in: text) else {
            return nil
        }
        return String(text[r])
    }

    private static func localizationKey(from keyAndValue: String.LocalizationValue) -> String {
        if let mirroredKey = Mirror(reflecting: keyAndValue).descendant("key") as? String, !mirroredKey.isEmpty {
            return mirroredKey
        }
        let description = String(describing: keyAndValue)
        if let regex = try? NSRegularExpression(pattern: "key\\s*:\\s*\"([^\"]+)\""),
           let match = regex.firstMatch(
               in: description,
               range: NSRange(location: 0, length: (description as NSString).length)
           ),
           let key = substring(in: description, range: match.range(at: 1)) {
            return key
        }
        return description
    }

    private static func resolvedString(
        for key: String,
        table: String?,
        bundle: Bundle,
        defaultValue: String? = nil,
        foundInCatalog: inout Bool
    ) -> String {
        let bundles = self.localizationBundles(preferred: bundle)
        for candidate in bundles {
            let value = candidate.localizedString(forKey: key, value: nil, table: table)
            if self.isResolved(value, for: key) {
                foundInCatalog = true
                return value
            }
        }

        foundInCatalog = false
        if let defaultValue {
            return defaultValue
        }
        return key
    }

    private static func resolvedString(
        for key: String,
        table: String?,
        bundle: Bundle,
        defaultValue: String? = nil
    ) -> String {
        var found = false
        return self.resolvedString(
            for: key,
            table: table,
            bundle: bundle,
            defaultValue: defaultValue,
            foundInCatalog: &found
        )
    }

    private static func localizationBundles(preferred: Bundle) -> [Bundle] {
        var bundles: [Bundle] = [preferred]
        if preferred.bundleURL != Bundle.main.bundleURL {
            bundles.append(.main)
        }
        if preferred.bundleURL != Bundle.module.bundleURL {
            bundles.append(.module)
        }
        return bundles
    }

    private static func isResolved(_ value: String, for key: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != key
    }
}
