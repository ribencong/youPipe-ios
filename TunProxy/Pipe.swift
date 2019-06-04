//
//  Tunnel.swift
//  TunProxy
//
//  Created by wsli on 2019/6/3.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

typealias CloseCallBack = ()->Void

public struct HTTPData {
        public static let DoubleCRLF = "\r\n\r\n".data(using: String.Encoding.utf8)!
        public static let CRLF = "\r\n".data(using: String.Encoding.utf8)!
        public static let ConnectSuccessResponse = "HTTP/1.1 200 Connection Established\r\n\r\n".data(using: String.Encoding.utf8)!
}

public enum PipeStatus: Int {
        case invalid = 0,
        
        ProxyFirstRequest = 1,
        ProxyConnectResponse,
        ProxyWriteOut,
        ProxyReadIn,
        
        AdapterWriteOut,
        AdapterReadIn
}

class Pipe: NSObject{
        var KeyPort:UInt16?=0
        
        private var targetAddr:String?
        private var targetoPort:UInt16?
        private var isConnect:Bool = false
        var firstHeaderData:Data? 
        private var pipeStatus: PipeStatus = .invalid
        
        private var proxySock: GCDAsyncSocket
        private var adapterSock: GCDAsyncSocket?
        private var CCB:CloseCallBack?
        
        init(psock:GCDAsyncSocket, callBack:@escaping CloseCallBack) {
                
                proxySock = psock
                self.CCB = callBack
                super.init()
                self.proxySock.delegate = self
                self.proxySock.readData(to: HTTPData.DoubleCRLF,
                                        withTimeout: -1,
                                        tag: PipeStatus.ProxyFirstRequest.rawValue)
        }
        
        func Close() {
                self.CCB?()
                self.proxySock.disconnectAfterReadingAndWriting()
                self.adapterSock?.disconnectAfterReadingAndWriting()
        }
}

extension Pipe: GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
                do {
                        switch (PipeStatus.init(rawValue: tag))!{
                        case .ProxyFirstRequest:
                                let header = try HTTPHeader(headerData: data)
                                NSLog("---[\(self.KeyPort!)]---=>:ProxyFirstRequest \(header.toString())......")
                                try self.OpenAdapter(header: header)
                                break
                                
                        case .ProxyReadIn:
                                self.adapterSock?.write(data,
                                                        withTimeout: -1,
                                                        tag: PipeStatus.AdapterWriteOut.rawValue)
                                break
                                
                        case .AdapterReadIn:
                                NSLog("---[\(self.KeyPort!)]---=>:AdapterReadIn......\(data.count)")
                                self.proxySock.write(data,
                                                     withTimeout: -1,
                                                     tag: PipeStatus.ProxyWriteOut.rawValue)
                                break
                        default:
                                NSLog("---[\(self.KeyPort!)]---=>:didRead unknown......")
                                return
                        }
                        
                } catch let error {
                        NSLog("---[\(self.KeyPort!)]---=>:data len=\(data.count) err=\(error.localizedDescription)")
                        Close()
                        return
                }
        }
        
        open func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
                
                NSLog("---[\(self.KeyPort!)]--->Pipe:didConnectToHost:\(host):\(port)")

                if self.isConnect{
                        self.proxySock.write(HTTPData.ConnectSuccessResponse,
                                             withTimeout: -1,
                                             tag: PipeStatus.ProxyConnectResponse.rawValue)
                }else{
                        self.adapterSock?.write(self.firstHeaderData!,
                                                withTimeout: -1,
                                                tag: PipeStatus.AdapterWriteOut.rawValue)
                        
                        self.adapterSock?.readData(withTimeout: -1,
                                                   tag: PipeStatus.AdapterReadIn.rawValue)
                }
        }
        
        open func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
                
                switch (PipeStatus.init(rawValue: tag))! {
                        
                case .ProxyConnectResponse:
                        NSLog("---[\(self.KeyPort!)]---=>:ProxyConnectResponse......")
                        
                        self.proxySock.readData(withTimeout: -1,
                                                tag: PipeStatus.ProxyReadIn.rawValue)
                        
                        self.adapterSock?.readData(withTimeout: -1,
                                                   tag: PipeStatus.AdapterReadIn.rawValue)
                        break
                        
                case .AdapterWriteOut:
                        NSLog("---[\(self.KeyPort!)]---=>:AdapterWriteOut......")
                        if self.isConnect {
                                self.proxySock.readData(withTimeout: -1,
                                                        tag: PipeStatus.ProxyReadIn.rawValue)
                        }else {
                                self.proxySock.readData(to: HTTPData.DoubleCRLF,
                                                        withTimeout: -1,
                                                        tag: PipeStatus.ProxyReadIn.rawValue)
                        }
                        
                        break
                        
                case .ProxyWriteOut:
                        NSLog("---[\(self.KeyPort!)]---=>:ProxyWriteOut......")
                        self.adapterSock?.readData(withTimeout: -1,
                                                   tag: PipeStatus.AdapterReadIn.rawValue)
                        break
                default:
                        NSLog("---[\(self.KeyPort!)]---=>:didWriteDataWithTag unknown......")
                        return
                }
        }
        
        open func socketDidDisconnect(_ socket: GCDAsyncSocket, withError err: Error?) {
                self.Close()
                NSLog("---[\(self.KeyPort!)]---=>:socketDidDisconnect......\(err.debugDescription)")
        }
}

extension Pipe {
        
        func OpenAdapter(header:HTTPHeader) throws {
                
//                if header.isConnect{
//                        NSLog("---[\(self.KeyPort!)]---=>:暂时不处理, 方便测试:\(header.toString())")
//                        throw YPError.SystemError
//                }
                
                self.targetAddr = header.host
                self.targetoPort = UInt16(header.port)
                self.isConnect = header.isConnect
                
                if !self.isConnect{
                        self.firstHeaderData = header.rawHeader
                }
                
                self.adapterSock = GCDAsyncSocket(delegate: self, delegateQueue:
                        HttpProxy.queue, socketQueue: HttpProxy.queue)
                
                try self.adapterSock?.connect(toHost: self.targetAddr!,
                                              onPort: self.targetoPort!)
        }
}
