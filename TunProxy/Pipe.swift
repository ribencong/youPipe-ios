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
        
        ProxyGetTarget = 1,
        ProxyConnectResponse,
        ProxyWriteBackResponse,
        
        AdapterWriteOut,
        AdapterWaitResponse
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
                                        tag: PipeStatus.ProxyGetTarget.rawValue)
        }
        
        func Close() {
                self.CCB?()
                self.proxySock.disconnect()
                self.adapterSock?.disconnect()
        }
}

extension Pipe: GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
                do {
                        switch (PipeStatus.init(rawValue: tag))!{
                        case .ProxyGetTarget:
                                let header = try HTTPHeader(headerData: data)
                                try self.OpenAdapter(header: header)
                        case .AdapterWaitResponse:
                                NSLog("------=>:AdapterWaitResponse......\(data.count)")
                                self.proxySock.write(data,
                                                     withTimeout: -1,
                                                     tag: PipeStatus.ProxyWriteBackResponse.rawValue)
                                break;
                        default:
                                NSLog("------=>:didRead unknown......")
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

                if self.isConnect{
                        self.proxySock.write(HTTPData.ConnectSuccessResponse,
                                             withTimeout: -1,
                                             tag: PipeStatus.ProxyConnectResponse.rawValue)
                }else{
                        self.adapterSock!.write(self.firstHeaderData!,
                                                withTimeout: -1,
                                                tag: PipeStatus.AdapterWriteOut.rawValue)
                        
                        self.proxySock.readData(withTimeout: -1,
                                                   tag: PipeStatus.AdapterWaitResponse.rawValue)
                }
        }
        
        open func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
                
                switch (PipeStatus.init(rawValue: tag))! {
                case .ProxyConnectResponse:
                        NSLog("------=>:ProxyConnectResponse......")
                        break
                case .AdapterWriteOut:
                        NSLog("------=>:AdapterWriteOut......")
                        break
                case .ProxyWriteBackResponse:
                        NSLog("------=>:ProxyWriteBackResponse......")
                        break
                default:
                        NSLog("------=>:didWriteDataWithTag unknown......")
                        return
                }
        }
        
        open func socketDidDisconnect(_ socket: GCDAsyncSocket, withError err: Error?) {
                NSLog("------=>:socketDidDisconnect......\(err.debugDescription)")
                self.Close()
        }
}

extension Pipe {
        
        func OpenAdapter(header:HTTPHeader) throws {
                
                if header.isConnect{
                        NSLog("------=>:暂时不处理, 方便测试:\(header.toString())")
                        throw YPError.SystemError
                }
                
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
