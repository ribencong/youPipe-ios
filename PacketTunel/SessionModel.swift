//
//  SessionModel.swift
//  Sniffer
//
//  Created by ZapCannon87 on 01/09/2017.
//  Copyright © 2017 zapcannon87. All rights reserved.
//

import Foundation
import QuartzCore

class SessionModel: Hashable, Equatable {
    
    /* Hashable */
    var hashValue: Int {
        return self.index
    }
        
         func hash(into hasher: inout Hasher){
                hasher.combine(index)
        }
    
    /* Equatable */
    static func == (lhs: SessionModel, rhs: SessionModel) -> Bool {
        return lhs.index == rhs.index
    }
    
    var index: Int = -1
    
    var date: Double? {
        get {
            return self.dic.value(for: "date")
        }
        set {
            self.dic["date"] = newValue
        }
    }
    
    var method: String? {
        get {
            return self.dic.value(for: "method")
        }
        set {
            self.dic["method"] = newValue
        }
    }
    
    var userAgent: String? {
        get {
            return self.dic.value(for: "userAgent")
        }
        set {
            self.dic["userAgent"] = newValue
        }
    }
    
    var url: String? {
        get {
            return self.dic.value(for: "url")
        }
        set {
            self.dic["url"] = newValue
        }
    }
    
    var host: String? {
        get {
            return self.dic.value(for: "host")
        }
        set {
            self.dic["host"] = newValue
        }
    }
    
    var localIP: String? {
        get {
            return self.dic.value(for: "localIP")
        }
        set {
            self.dic["localIP"] = newValue
        }
    }
    
    var localPort: Int? {
        get {
            return self.dic.value(for: "localPort")
        }
        set {
            self.dic["localPort"] = newValue
        }
    }
    
    var remoteIP: String? {
        get {
            return self.dic.value(for: "remoteIP")
        }
        set {
            self.dic["remoteIP"] = newValue
        }
    }
    
    var remotePort: Int? {
        get {
            return self.dic.value(for: "remotePort")
        }
        set {
            self.dic["remotePort"] = newValue
        }
    }
    
    var uploadTraffic: Int = 0
    
    var downloadTraffic: Int = 0
    
    enum sessionStatus: String {
        case connect = "Connect"
        case active = "Active"
        case sendRequest = "SendRequest"
        case receiveResponse = "ReceiveResponse"
        case finish = "Finish"
        case close = "Close"
        case null = "Null"
    }
    
    var status: sessionStatus {
        get {
            if
                let value: String = self.dic.value(for: "status"),
                let status: sessionStatus = sessionStatus.init(rawValue: value)
            {
                return status
            } else {
                return .null
            }
        }
        set {
            let oldValue: SessionModel.sessionStatus = self.status
            switch (oldValue, newValue) {
            case (.null, .connect):
                self.insertTiming(type: .establishing, status: .start)
            case (.connect, _):
                if newValue == .close {
                    break
                }
                self.insertTiming(type: .establishing, status: .end)
                if newValue == .active {
                    self.insertTiming(type: .transmitting, status: .start)
                } else if newValue == .sendRequest {
                    self.insertTiming(type: .requestSending, status: .start)
                } else {
                    assertionFailure("error in session status: \(oldValue) \(newValue)")
                }
            case (.active, .close), (.active, .finish):
                self.insertTiming(type: .transmitting, status: .end)
            case (.sendRequest, _):
                if newValue == .close {
                    break
                }
                self.insertTiming(type: .requestSending, status: .end)
                if newValue == .receiveResponse {
                    self.insertTiming(type: .responseReceiving, status: .start)
                } else {
                    assertionFailure("error in session status: \(oldValue) \(newValue)")
                }
            case (.receiveResponse, _):
                if newValue == .close {
                    break
                }
                if newValue == .finish {
                    self.insertTiming(type: .responseReceiving, status: .end)
                } else {
                    assertionFailure("error in session status: \(oldValue) \(newValue)")
                }
            default:
                assertionFailure("error in session status: \(oldValue) \(newValue)")
            }
            self.dic["status"] = newValue.rawValue
        }
    }
    
    enum timingType: String {
        case establishing = "Establishing"
        case requestSending = "RequestSending"
        case responseReceiving = "ResponseReceiving"
        case transmitting = "Transmitting"
    }
    
    enum timingTypeStatus: String {
        case start = "start"
        case end = "end"
    }
    
    private func insertTiming(type: timingType, status: timingTypeStatus) {
        
        let date: Double = CACurrentMediaTime()
        var newTimings: [String : [String : Double]]
        
        if var timings: [String : [String : Double]] = self.timings
        {
            /* update timing status */
            var newType: [String : Double] = timings[type.rawValue] ?? [:]
            newType.updateValue(date, forKey: status.rawValue)
            
            /* update timing */
            timings.updateValue(newType, forKey: type.rawValue)
            newTimings = timings
            
        } else {
            newTimings = [type.rawValue : [status.rawValue : date]]
        }
        
        self.timings = newTimings
    }
    
    private(set) var timings: [String : [String : Double]]? {
        get {
            return self.dic.value(for: "timings")
        }
        set {
            self.dic["timings"] = newValue
        }
    }
    
    func getTiming(type: timingType, dic: [String : [String : Double]]) -> Double? {
        if let timing: [String : Double] = dic.value(for: type.rawValue)
        {
            if
                let start: Double = timing[SessionModel.timingTypeStatus.start.rawValue],
                let end: Double = timing[SessionModel.timingTypeStatus.end.rawValue]
            {
                return end - start
            } else {
                return -1
            }
        } else {
            return nil
        }
    }
    
    var note: String? {
        get {
            return self.dic.value(for: "note")
        }
        set {
            self.dic["note"] = newValue
        }
    }
    
    var requestHeaders: String? {
        get {
            return self.dic.value(for: "requestHeaders")
        }
        set {
            self.dic["requestHeaders"] = newValue
        }
    }
    
    var responseHeaders: String? {
        get {
            return self.dic.value(for: "responseHeaders")
        }
        set {
            self.dic["responseHeaders"] = newValue
        }
    }
    
    private var dic: [String : Any]
    
    init() {
        self.dic = [:]
    }
    
    init(dic: [String : Any]) {
        self.dic = dic
        if let index: Int = dic.value(for: "index") {
            self.index = index
        }
        if let uploadTraffic: Int = dic.value(for: "uploadTraffic") {
            self.uploadTraffic = uploadTraffic
        }
        if let downloadTraffic: Int = dic.value(for: "downloadTraffic") {
            self.downloadTraffic = downloadTraffic
        }
    }
    
    func getDic() -> [String : Any] {
        var dic = self.dic
        dic.updateValue(self.index, forKey: "index")
        dic.updateValue(self.uploadTraffic, forKey: "uploadTraffic")
        dic.updateValue(self.downloadTraffic, forKey: "downloadTraffic")
        return dic
    }
    
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    
    func value<T>(for key: Key) -> T? {
        guard let any: Any = self[key] else {
            return nil
        }
        if let value: T = any as? T {
            return value
        } else {
            switch T.self {
            case is String.Type:
                switch any {
                case let someInt as Int:
                    return String(someInt) as? T
                case let someDouble as Double:
                    return String(someDouble) as? T
                case let someBool as Bool:
                    return String(someBool) as? T
                default:
                    return nil
                }
            case is Int.Type:
                if let someString: String = any as? String {
                    return Int(someString) as? T
                } else if let someDouble: Double = any as? Double {
                    return Int(someDouble) as? T
                } else {
                    return nil
                }
            case is Double.Type:
                if let someString: String = any as? String {
                    return Double(someString) as? T
                } else if let someInt: Int = any as? Int {
                    return Double(someInt) as? T
                } else {
                    return nil
                }
            case is Bool.Type:
                if let someString: String = any as? String {
                    return Bool(someString) as? T
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
    }
    
}
