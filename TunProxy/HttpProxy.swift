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
        
        init?(port:Int){
                super.init()
                
                do{
                        self.listenSocket = try Socket.create()
                        
                        try listenSocket?.listen(on: port)
                        
                        
                }catch let err{
                        NSLog("Start http proxy failed:\(err.localizedDescription)")
                        return nil
                }
        }
        
        func Run(){
                let queue = DispatchQueue.global(qos: .userInteractive)
                
                queue.async {
                        [unowned self] in
                       
                        do {
                                while self.RunOk{
                                        
                                        guard let newSocket = try self.listenSocket?.acceptClientConnection() else{
                                                NSLog("Accepting exit......")
                                                return
                                        }
                                        
                                        NSLog("New accept proxy[\(newSocket.remoteHostname):\(newSocket.remotePort)]")
                                        queue.sync {
                                                let newTunnel = Pipe(psock: newSocket){
                                                        HttpProxy.TunnelCache.removeValue(forKey: newSocket.socketfd)
                                                }
                                                
                                                HttpProxy.TunnelCache[newSocket.socketfd] = newTunnel
                                        }
                                }
                        }catch let err{
                                NSLog("Http proxy exit......\(err.localizedDescription)")
                                return
                        }
                }
        }
        
        func Close(){
                self.listenSocket?.close()
                exit(EXIT_FAILURE)
        }
}
