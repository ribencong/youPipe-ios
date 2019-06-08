//
//  HttpProxy.swift
//  TunProxy
//
//  Created by wsli on 2019/6/3.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class HttpProxy:NSObject{
        
        fileprivate var listenSocket: GCDAsyncSocket!
        static var TunnelCache:Dictionary<UInt16, Pipe> = [:]
        
        static let queue = DispatchQueue(label: "com.ribencong.HttpQueue")
        
        init?(host:String, port:UInt16){
                super.init()
                
                listenSocket = GCDAsyncSocket(delegate: self, delegateQueue: HttpProxy.queue, socketQueue: HttpProxy.queue)
                
                do{
                        try listenSocket.accept(onInterface: host, port: port)
                }catch let err{
                        NSLog("Start http proxy failed:\(err.localizedDescription)")
                        exit(EXIT_FAILURE)
                }
        }
        
        func Close(){
                self.listenSocket.disconnect()
        }
}

extension HttpProxy:GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
                
                let keyPort = newSocket.connectedPort
                
                let newTunnel = Pipe(psock: newSocket){
                        HttpProxy.TunnelCache.removeValue(forKey: keyPort)
                }
                newTunnel.KeyPort = keyPort
                
                HttpProxy.TunnelCache[keyPort] = newTunnel
        }
}
