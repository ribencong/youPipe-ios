//
//  HttpProxy.swift
//  TunProxy
//
//  Created by wsli on 2019/6/3.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import Socket

class HttpProxy:NSObject{
        
        fileprivate var listenSocket: Socket?
        private var RunOk:Bool = true
        
        static var TunnelCache:Dictionary<Int32, Pipe> = [:]
        static let queue = DispatchQueue(label: "com.ribencong.HttpQueue")
        
        init?(host:String, port:Int){
                super.init()
                
                do{
                        self.listenSocket = try Socket.create()
                        try self.listenSocket?.listen(on: port, node:host)
                        
                }catch let err{
                        NSLog("---HttpProxy--=>:Start http proxy failed:\(err.localizedDescription)")
                        return nil
                }
        }
        
        func Run(){
                let queue = DispatchQueue.global(qos: .default)
                let socket = self.listenSocket!
                queue.async {
                        [unowned self, socket] in
                       
                        do {
                                while self.RunOk{
                                        let newSocket = try socket.acceptClientConnection() 
                                        
                                        NSLog("---HttpProxy--=>:New accept proxy[\(newSocket.remoteHostname):\(newSocket.remotePort)]")
                                        queue.sync {
                                                let newTunnel = Pipe(psock: newSocket){
                                                        HttpProxy.TunnelCache.removeValue(forKey: newSocket.socketfd)
                                                }
                                                
                                                HttpProxy.TunnelCache[newSocket.socketfd] = newTunnel
                                        }
                                }
                        }catch let err{
                                NSLog("---HttpProxy--=>:Http proxy exit......\(err.localizedDescription)")
                                return
                        }
                }
        }
        
        func Close(){
                self.listenSocket?.close()
                exit(EXIT_FAILURE)
        }
}
