//
//  FreePipe.swift
//  PacketTunel
//
//  Created by wsli on 2019/5/28.
//  Copyright © 2019 ribencong. All rights reserved.
//

import Foundation
import CocoaAsyncSocket


struct Action {
        static let ReadReqHead:Int = 1
        static let WriteConnectHeader = 2
        static let WriteReqHead = 3
}

class Pipe: NSObject{
        var inSock:GCDAsyncSocket
        var normalConn:HTTPConnection?
        var outSock:GCDAsyncSocket
        var IsFreePipe:Bool = true
        var requestHeader:SimpleHttpHeader?
        
        let queue: DispatchQueue = DispatchQueue(label: "HTTPConnection.delegateQueue")
        var finishCall : ((Pipe)->Void)? = nil
        
        init(inSock : GCDAsyncSocket, completeHandler:@escaping (Pipe) -> Void){
                self.inSock = inSock
                self.finishCall = completeHandler
                self.outSock = GCDAsyncSocket()
                super.init()
                
                self.outSock.synchronouslySetDelegate(
                        self,
                        delegateQueue: queue
                )
                self.inSock.synchronouslySetDelegate(
                        self,
                        delegateQueue: queue
                )
                self.inSock.readData(withTimeout: 5, tag: Action.ReadReqHead)
        }
        
        func ClosePipe(){
                self.finishCall?(self)
                self.outSock.disconnectAfterWriting()
                self.inSock.disconnectAfterWriting()
        }
}

extension Pipe: GCDAsyncSocketDelegate {
        
        func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int){
                do  {
                         try self.firstHandShake(data: data)
                }catch let err{
                        NSLog("process DidRead func err\(err.localizedDescription)")
                        self.ClosePipe()
                }
        }
        
        func firstHandShake(data:Data) throws{ 
                guard let header  = SimpleHttpHeader(data: data) else{
                        NSLog("Failed parse http header")
                        return
                }
                NSLog("m:\(header.method!.rawValue) u:\(header.url!) h:\(header.host!) p:\(header.port)")
                
                guard let host = header.host else {
                        NSLog("Firsh handshke failed ,no host")
                        return
                }
                
                self.requestHeader = header
                
                let needProxy = DomainCache.shared.Hit(by:host)
                if needProxy{
                        self.IsFreePipe = false
                        try self.outSock.connect(toHost: "127.0.0.1", onPort: UInt16(socksPort))
                }else{
                        self.normalConn = HTTPConnection(incomingSocket: self.inSock,
                                                         requestData: self.requestHeader!.rawData)
                }
        }
        
        func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
                assert(self.outSock == sock, "error in sock")
                NSLog("---=>:This must be payment conn \(host) : \(port)")
        }
}
