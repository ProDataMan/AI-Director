import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum OBSWebSocketClientError: Error, Sendable, Equatable {
    case invalidURL
    case notConnected
    case unsupportedMessage
    case malformedMessage
}

public actor OBSWebSocketClient {
    public enum ConnectionState: Sendable, Equatable {
        case disconnected
        case connecting
        case connected
    }

    private let url: URL
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var receiveLoopTask: Task<Void, Never>?

    public private(set) var state: ConnectionState = .disconnected

    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    public func connect() async throws {
        guard state == .disconnected else { return }
        state = .connecting

        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        state = .connected

        receiveLoopTask = Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    public func disconnect() async {
        receiveLoopTask?.cancel()
        receiveLoopTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        state = .disconnected
    }

    public func send<T: Encodable & Sendable>(_ value: T) async throws {
        guard let task else { throw OBSWebSocketClientError.notConnected }
        let data = try JSONEncoder().encode(value)
        guard let text = String(data: data, encoding: .utf8) else {
            throw OBSWebSocketClientError.malformedMessage
        }
        try await task.send(.string(text))
    }

    private func receiveLoop() async {
        guard let task else { return }

        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                switch message {
                case .string:
                    break
                case .data:
                    break
                @unknown default:
                    break
                }
            } catch {
                state = .disconnected
                self.task = nil
                return
            }
        }
    }
}
