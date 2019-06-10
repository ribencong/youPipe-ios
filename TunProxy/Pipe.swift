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
        private var isConnCmd:Bool = false
        var firstHeaderData:Data? 
        private var pipeStatus: PipeStatus = .invalid
        
        private var proxySock: GCDAsyncSocket
        private var adapter: Adapter?
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
                self.adapter?.byePeer()
        }
}

extension Pipe: GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
                do {
                        switch (PipeStatus.init(rawValue: tag))!{
                        case .ProxyFirstRequest:
                                let header = try HTTPHeader(headerData: data)
                                NSLog("---Pipe[\(self.KeyPort!)]---=>:ProxyFirstRequest \(header.toString())......")
                                try self.OpenAdapter(header: header)
                                break
                                
                        case .ProxyReadIn:
                                self.adapter?.write(data: data, tag: PipeStatus.AdapterWriteOut.rawValue)
                                break
                                
                        case .AdapterReadIn:
                                NSLog("---Pipe[\(self.KeyPort!)]---=>:AdapterReadIn......\(data.count)")
                                self.proxySock.write(data,
                                                     withTimeout: -1,
                                                     tag: PipeStatus.ProxyWriteOut.rawValue)
                                break
                        default:
                                NSLog("---Pipe[\(self.KeyPort!)]---=>:didRead unknown......")
                                return
                        }
                        
                } catch let error {
                        NSLog("---Pipe[\(self.KeyPort!)]---=>:data len=\(data.count) err=\(error.localizedDescription)")
                        Close()
                        return
                }
        }
        
        open func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
                
                NSLog("---Pipe[\(self.KeyPort!)]--->Pipe:didConnectToHost:\(host):\(port)")

                if self.isConnCmd{
                        self.proxySock.write(HTTPData.ConnectSuccessResponse,
                                             withTimeout: -1,
                                             tag: PipeStatus.ProxyConnectResponse.rawValue)
                }else{
                        self.adapter?.write(data: self.firstHeaderData!,  tag: PipeStatus.AdapterWriteOut.rawValue)
                        
                        self.adapter?.readData(tag: PipeStatus.AdapterReadIn.rawValue)
                }
        }
        
        open func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
                
                switch (PipeStatus.init(rawValue: tag))! {
                        
                case .ProxyConnectResponse:
                        NSLog("---[\(self.KeyPort!)]---=>:ProxyConnectResponse......")
                        self.proxySock.readData(withTimeout: -1,
                                                tag: PipeStatus.ProxyReadIn.rawValue)
                        
                        self.adapter?.readData(tag: PipeStatus.AdapterReadIn.rawValue)
                        break
                        
                case .AdapterWriteOut:
                        NSLog("---[\(self.KeyPort!)]---=>:AdapterWriteOut......")
                        if self.isConnCmd {
                                self.proxySock.readData(withTimeout: -1,
                                                        tag: PipeStatus.ProxyReadIn.rawValue)
                        }else {
                                self.proxySock.readData(to: HTTPData.DoubleCRLF,
                                                        withTimeout: -1,
                                                        tag: PipeStatus.ProxyReadIn.rawValue)
                        }
                        
                        break
                        
                case .ProxyWriteOut:
                        NSLog("---Pipe[\(self.KeyPort!)]---=>:ProxyWriteOut......")
                        self.adapter?.readData(tag: PipeStatus.AdapterReadIn.rawValue)
                        break
                default:
                        NSLog("---Pipe[\(self.KeyPort!)]---=>:didWriteDataWithTag unknown......")
                        return
                }
        }
        
        open func socketDidDisconnect(_ socket: GCDAsyncSocket, withError err: Error?) {
                self.Close()
                NSLog("---Pipe[\(self.KeyPort!)]---=>:socketDidDisconnect......\(err.debugDescription)")
        }
}

extension Pipe {
        
        func OpenAdapter(header:HTTPHeader) throws {

                self.targetAddr = header.host
                self.targetoPort = UInt16(header.port)
                self.isConnCmd = header.isConnect
                
                if !self.isConnCmd{
                        self.firstHeaderData = header.rawHeader
                }
                if Domains.shared.Hit(host: header.host){
                        self.adapter = PipeAdapter(targetHost: self.targetAddr!,
                                                   targetPort: self.targetoPort!,
                                                   delegae: self)
                }else{
                        self.adapter = DirectAdapter(targetHost: self.targetAddr!,
                                             targetPort: self.targetoPort!,
                                             delegae: self)
                }
        }
}
