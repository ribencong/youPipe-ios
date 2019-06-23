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
        
        var TunnelCache:Dictionary<Int32, Pipe> = [:]
        let queue = DispatchQueue(label: "com.ribencong.HttpQueue")
        
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
                
                queue.async {
                        while self.RunOk{ do {
                               
                                let newSocket = try self.listenSocket!.acceptClientConnection()
                                
                                NSLog("---HttpProxy--=>:New accept proxy[\(newSocket.remoteHostname):\(newSocket.remotePort)]")
                               
                                let newTunnel = Pipe(psock: newSocket){
                                        NSLog("---HttpProxy--=>:Http proxy remove \(newSocket.socketfd) from TunnelCache")
                                        self.TunnelCache.removeValue(forKey: newSocket.socketfd)
                                }
                                
                                self.TunnelCache[newSocket.socketfd] = newTunnel
                                
                                }catch let err{
                                        NSLog("---HttpProxy--=>:Http proxy exit......\(err.localizedDescription)")
                                        return
                                } }
                }
        }
        
        func Close(){
                self.listenSocket?.close()
                exit(EXIT_FAILURE)
        }
}
