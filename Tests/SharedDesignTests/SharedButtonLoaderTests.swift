import SwiftUI
import Testing
@testable import SharedDesign

@Suite("SharedButton loader hook")
@MainActor
struct SharedButtonLoaderTests {
    @Test("No loader is set by default, so SharedButton keeps its built-in spinner")
    func defaultsToBuiltIn() {
        #expect(EnvironmentValues().sharedButtonLoader == nil)
    }

    @Test("A supplied loader receives the button's style and tint")
    func passesStyleAndTint() {
        var received: [SharedButton.Style] = []
        var values = EnvironmentValues()
        values.sharedButtonLoader = { style, _ in
            received.append(style)
            return AnyView(EmptyView())
        }
        _ = values.sharedButtonLoader?(.secondary, .red)
        #expect(received == [.secondary])
    }
}
