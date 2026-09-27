import StudioCore

public actor StudioDirector {
    public private(set) var state: StudioState

    public init(initialState: StudioState = .disconnected) {
        self.state = initialState
    }

    public func transition(to newState: StudioState) {
        state = newState
    }
}
