//
//  File.swift
//
//
//  Created by Eduardo Vazquez on 2/20/24.
//

import Foundation

class BinaryDecoder {
    enum Kind: UInt8 {
        case push = 0 // Assuming values for example
        case reply = 1
        case broadcast = 2
    }
    
    let HEADER_LENGTH = 1 // Adjust based on your actual header length
    let META_LENGTH = 4 // Adjust based on your actual meta length
    
    func binaryDecode(buffer: Data) -> Any? {
        guard buffer.count > 1, let kind = Kind(rawValue: buffer[0]) else { return nil }
        
        switch kind {
        case .push:
            return decodePush(buffer: buffer)
        case .reply:
            return decodeReply(buffer: buffer)
        case .broadcast:
            return decodeBroadcast(buffer: buffer)
        }
    }
    
    private func decodePush(buffer: Data) -> [String: Any?]? {
        let joinRefSize = Int(buffer[1])
        let topicSize = Int(buffer[2])
        let eventSize = Int(buffer[3])
        var offset = HEADER_LENGTH + META_LENGTH - 1 // pushes have no ref
        let joinRef = String(data: buffer.subdata(in: offset..<(offset + joinRefSize)), encoding: .utf8)
        offset += joinRefSize
        let topic = String(data: buffer.subdata(in: offset..<(offset + topicSize)), encoding: .utf8)
        offset += topicSize
        let event = String(data: buffer.subdata(in: offset..<(offset + eventSize)), encoding: .utf8)
        offset += eventSize
        let data = buffer.subdata(in: offset..<buffer.count)
        
        return ["join_ref": joinRef, "ref": nil, "topic": topic, "event": event, "payload": data]
    }
    
    private func decodeReply(buffer: Data) -> [String: Any?]? {
        let joinRefSize = Int(buffer[1])
        let refSize = Int(buffer[2])
        let topicSize = Int(buffer[3])
        let eventSize = Int(buffer[4])
        var offset = HEADER_LENGTH + META_LENGTH
        let joinRef = String(data: buffer.subdata(in: offset..<(offset + joinRefSize)), encoding: .utf8)
        offset += joinRefSize
        let ref = String(data: buffer.subdata(in: offset..<(offset + refSize)), encoding: .utf8)
        offset += refSize
        let topic = String(data: buffer.subdata(in: offset..<(offset + topicSize)), encoding: .utf8)
        offset += topicSize
        let event = String(data: buffer.subdata(in: offset..<(offset + eventSize)), encoding: .utf8)
        offset += eventSize
        let data = buffer.subdata(in: offset..<buffer.count)
        let payload = ["status": event, "response": data] as [String: Any]
        
        return ["join_ref": joinRef, "ref": ref, "topic": topic, "event": "reply", "payload": payload]
    }
    
    private func decodeBroadcast(buffer: Data) -> [String: Any?]? {
        let topicSize = Int(buffer[1])
        let eventSize = Int(buffer[2])
        var offset = HEADER_LENGTH + 2
        let topic = String(data: buffer.subdata(in: offset..<(offset + topicSize)), encoding: .utf8)
        offset += topicSize
        let event = String(data: buffer.subdata(in: offset..<(offset + eventSize)), encoding: .utf8)
        offset += eventSize
        let data = buffer.subdata(in: offset..<buffer.count)
        
        return ["join_ref": nil, "ref": nil, "topic": topic, "event": event, "payload": data]
    }
}
