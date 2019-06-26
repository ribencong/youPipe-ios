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
        
        var TunnelCache = [Int32:Pipe]()
        
        let httpQueue = DispatchQueue.global(qos: .userInteractive)
        let lockQueue = DispatchQueue(label: "com.ribencong.tunproxy.lock")
        
        init?(host:String, port:Int){
                super.init()
                
                do{
                        self.listenSocket = try Socket.create(family:.inet, type: .stream, proto: .tcp)
                        self.listenSocket!.readBufferSize = Pipe.PipeBufSize
                        try self.listenSocket!.listen(on: port, node:host)
                        NSLog("---HttpProxy--=>:Start http proxy Success:\(self.listenSocket!.remoteHostname) on port \(self.listenSocket!.remotePort)")
                }catch let err{
                        NSLog("---HttpProxy--=>:Start http proxy failed:\(err.localizedDescription)")
                        return nil
                }
        }
        
        deinit {
                //TODO:: Close all open sockets...
//                for socket in connectedSockets.values {
//                        socket.close()
//                }
                self.listenSocket?.close()
        }
        
        func Run(){
                
                self.httpQueue.async { [unowned self] in
                        
                        while self.RunOk{ do {
                               
                        let newSocket = try self.listenSocket!.acceptClientConnection()
                        let fd = newSocket.socketfd
                        NSLog("---HttpProxy--=>Accepted connection[\(fd)] from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                                
                        let newTunnel = Pipe(psock: newSocket){
                                fd in
                                self.lockQueue.sync{
                                        self.TunnelCache[fd] = nil
                                        NSLog("---HttpProxy--=>:Http proxy remove \(fd) from TunnelCache")
                                }
                        }
                                
                        self.lockQueue.sync{
                                self.TunnelCache[fd] = newTunnel
                        }
                        
                                
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
