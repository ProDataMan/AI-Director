import Foundation
import Testing
@testable import OBSKit

@Test func decodesHelloWithoutAuthentication() throws {
    let json = #"{"op":0,"d":{"obsWebSocketVersion":"5.6.0","rpcVersion":1}}"#
    let envelope = try JSONDecoder().decode(OBSHelloEnvelope.self, from: Data(json.utf8))
    #expect(envelope.op == 0)
    #expect(envelope.d.obsWebSocketVersion == "5.6.0")
    #expect(envelope.d.rpcVersion == 1)
    #expect(envelope.d.authentication == nil)
}

@Test func decodesHelloWithAuthentication() throws {
    let json = #"{"op":0,"d":{"obsWebSocketVersion":"5.6.0","rpcVersion":1,"authentication":{"challenge":"challenge","salt":"salt"}}}"#
    let envelope = try JSONDecoder().decode(OBSHelloEnvelope.self, from: Data(json.utf8))
    #expect(envelope.d.authentication?.challenge == "challenge")
    #expect(envelope.d.authentication?.salt == "salt")
}

@Test func encodesIdentify() throws {
    let envelope = OBSIdentifyEnvelope(rpcVersion: 1, authentication: "token", eventSubscriptions: 33)
    let data = try JSONEncoder().encode(envelope)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(object?["op"] as? Int == 1)
}

@Test func decodesRequestResponse() throws {
    let json = #"{"op":7,"d":{"requestType":"GetVersion","requestId":"abc","requestStatus":{"result":true,"code":100},"responseData":{"obsVersion":"31.0.0"}}}"#
    let response = try JSONDecoder().decode(OBSRequestResponseEnvelope.self, from: Data(json.utf8))
    #expect(response.d.requestId == "abc")
    #expect(response.d.requestStatus.result)
    #expect(response.d.responseData?["obsVersion"] == .string("31.0.0"))
}

@Test func decodesEvent() throws {
    let json = #"{"op":5,"d":{"eventType":"CurrentProgramSceneChanged","eventIntent":4,"eventData":{"sceneName":"AID - Presenter"}}}"#
    let event = try JSONDecoder().decode(OBSEventEnvelope.self, from: Data(json.utf8))
    #expect(event.d.eventType == "CurrentProgramSceneChanged")
    #expect(event.d.eventData?["sceneName"] == .string("AID - Presenter"))
}
