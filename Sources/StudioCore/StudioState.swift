public enum StudioState: String, Codable, Sendable, Equatable, CaseIterable {
    case disconnected
    case idle
    case preparing
    case ready
    case recording
    case paused
    case finishing
    case editing
    case failed
}
