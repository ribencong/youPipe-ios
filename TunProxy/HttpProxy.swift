//
//  HttpProxy.swift
//  TunProxy
//
//  Created by wsli on 2019/6/3.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import SocketSwift

class HttpProxy:NSObject{
        
        fileprivate var listenSocket: Socket?
        private var RunOk:Bool = true
        
        var TunnelCache:Dictionary<Int32, Pipe> = [:]
        let queue = DispatchQueue(label: "com.ribencong.HttpQueue")
        
        init?(host:String, port:Int){
                super.init()
                
                do{
                        self.listenSocket = try Socket(.inet, type: .stream, protocol: .tcp)
                        try self.listenSocket?.bind(port: Port(port), address: host)
                        try self.listenSocket?.listen()
                        
                }catch let err{
                        NSLog("---HttpProxy--=>:Start http proxy failed:\(err.localizedDescription)")
                        return nil
                }
        }
        
        func Run(){
                
                queue.async {
                        while self.RunOk{ do {
                               
                        guard let newSocket = try self.listenSocket?.accept() else{
                                NSLog("---HttpProxy--=>: accept failed")
                                return
                        }
                                
                        let address = Socket.addresses(newSocket)
                                NSLog("---HttpProxy--=>:New accept proxy [\(String(describing: address))]")
                       
                        let newTunnel = Pipe(psock: newSocket){
                                NSLog("---HttpProxy--=>:Http proxy remove \(newSocket.fileDescriptor) from TunnelCache")
                                self.queue.sync {
                                     self.TunnelCache.removeValue(forKey: newSocket.fileDescriptor)
                                }
                        }
                                
                        self.TunnelCache[newSocket.fileDescriptor] = newTunnel
                                
                        }catch let err{
                                NSLog("---HttpProxy--=>:Http proxy exit......\(err.localizedDescription)")
                                return
                        }}
                }
        }
        
        func Close(){
                self.listenSocket?.close()
                exit(EXIT_FAILURE)
        }
}
