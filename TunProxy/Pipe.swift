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
        case invalid = 0, readFirstHead = 1, readContent, sendingConnectResponse,
        readingContent, forwarding
}

class Pipe: NSObject{
        
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
                                        tag: PipeStatus.readFirstHead.rawValue)
        }
        
        func Close() {
                self.CCB?()
                self.proxySock.disconnect()
        }
}

extension Pipe: GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
                
                do {
                        switch (PipeStatus.init(rawValue: tag))!{
                        case .readFirstHead:
                                let header = try HTTPHeader(headerData: data)
                                try self.OpenAdapter(header: header)
                        case .forwarding:
                                NSLog("forwarding......")
                                break;
                        default:
                                return
                        }
                        
                } catch let error {
                        NSLog("\(error.localizedDescription)")
                        Close()
                        return
                }
        }
        
        open func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
                
                NSLog("------>Pipe:didConnectToHost:\(host):\(port)")
                
                guard sock == self.adapterSock else {
                        NSLog("It should be adapter socket connected")
                        exit(EXIT_FAILURE)
                }
                
                if self.isConnect{
                        self.proxySock.write(HTTPData.ConnectSuccessResponse,
                                             withTimeout: -1,
                                             tag: PipeStatus.sendingConnectResponse.rawValue)
                }else{
                        self.adapterSock!.write(self.firstHeaderData!,
                                                withTimeout: -1,
                                                tag: PipeStatus.readingContent.rawValue)
                        
                        self.adapterSock?.readData(withTimeout: -1, tag: PipeStatus.forwarding.rawValue)
                }
        }
        
        open func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
                switch (PipeStatus.init(rawValue: tag))! {
                case .sendingConnectResponse:
                        NSLog("sendingConnectResponse......")
                        break
                case .readingContent:
                        NSLog("sendingConnectResponse......")
                        break
                default:
                        return
                }
        }
        
        open func socketDidDisconnect(_ socket: GCDAsyncSocket, withError err: Error?) {
                NSLog("socketDidDisconnect......\(err.debugDescription)")
        }
        
}

extension Pipe {
        
        func OpenAdapter(header:HTTPHeader) throws {
                self.targetAddr = header.host
                self.targetoPort = UInt16(header.port)
                self.isConnect = header.isConnect
                if !self.isConnect{
                        header.removeProxyHeader()
                        header.rewriteToRelativePath()
                        self.firstHeaderData = header.toData()
                }
                
                self.adapterSock = GCDAsyncSocket(delegate: self, delegateQueue:
                        HttpProxy.queue, socketQueue: HttpProxy.queue)
                
                try self.adapterSock?.connect(toHost: self.targetAddr!,
                                              onPort: self.targetoPort!)
        }
}
