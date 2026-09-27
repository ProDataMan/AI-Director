import Foundation

public enum OBSOpCode: Int, Codable, Sendable {
    case hello = 0
    case identify = 1
    case identified = 2
    case reidentify = 3
    case event = 5
    case request = 6
    case requestResponse = 7
    case requestBatch = 8
    case requestBatchResponse = 9
}

public struct OBSHelloEnvelope: Codable, Sendable, Equatable {
    public let op: Int
    public let d: OBSHello
}

public struct OBSHello: Codable, Sendable, Equatable {
    public let obsWebSocketVersion: String
    public let rpcVersion: Int
    public let authentication: OBSAuthenticationChallenge?
}

public struct OBSAuthenticationChallenge: Codable, Sendable, Equatable {
    public let challenge: String
    public let salt: String
}

public struct OBSIdentifyEnvelope: Codable, Sendable, Equatable {
    public let op: Int
    public let d: OBSIdentify

    public init(rpcVersion: Int, authentication: String? = nil, eventSubscriptions: Int? = nil) {
        self.op = OBSOpCode.identify.rawValue
        self.d = OBSIdentify(
            rpcVersion: rpcVersion,
            authentication: authentication,
            eventSubscriptions: eventSubscriptions
        )
    }
}

public struct OBSIdentify: Codable, Sendable, Equatable {
    public let rpcVersion: Int
    public let authentication: String?
    public let eventSubscriptions: Int?
}

public struct OBSIdentifiedEnvelope: Codable, Sendable, Equatable {
    public let op: Int
    public let d: OBSIdentified
}

public struct OBSIdentified: Codable, Sendable, Equatable {
    public let negotiatedRpcVersion: Int
}

public struct OBSRequestEnvelope: Codable, Sendable, Equatable {
    public let op: Int
    public let d: OBSRequest

    public init(requestType: String, requestId: String, requestData: [String: JSONValue]? = nil) {
        self.op = OBSOpCode.request.rawValue
        self.d = OBSRequest(requestType: requestType, requestId: requestId, requestData: requestData)
    }
}

public struct OBSRequest: Codable, Sendable, Equatable {
    public let requestType: String
    public let requestId: String
    public let requestData: [String: JSONValue]?
}

public struct OBSRequestResponseEnvelope: Codable, Sendable, Equatable {
    public let op: Int
    public let d: OBSRequestResponse
}

public struct OBSRequestResponse: Codable, Sendable, Equatable {
    public let requestType: String
    public let requestId: String
    public let requestStatus: OBSRequestStatus
    public let responseData: [String: JSONValue]?
}

public struct OBSRequestStatus: Codable, Sendable, Equatable {
    public let result: Bool
    public let code: Int
    public let comment: String?
}

public struct OBSEventEnvelope: Codable, Sendable, Equatable {
    public let op: Int
    public let d: OBSEvent
}

public struct OBSEvent: Codable, Sendable, Equatable {
    public let eventType: String
    public let eventIntent: Int
    public let eventData: [String: JSONValue]?
}

public enum JSONValue: Codable, Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([String: JSONValue].self) { self = .object(value) }
        else { self = .array(try container.decode([JSONValue].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}
