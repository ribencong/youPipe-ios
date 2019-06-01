//
//  HttpServer.swift
//  TunProxy
//
//  Created by wsli on 2019/6/1.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
class HttpProxy: NSObject{
        
        static let shared = HttpProxy()
        
        let listenSocket: GCDAsyncSocket
        let taskQueue:DispatchQueue
        var connections: Set<HTTPConnection> = []
        
        override init() {
                self.listenSocket = GCDAsyncSocket()
                taskQueue = DispatchQueue(label: "com.ribencong.httpserver",  attributes: .concurrent)
                super.init()
                
                self.listenSocket.synchronouslySetDelegate(
                        self,
                        delegateQueue: taskQueue
                )
        }
        
        func start(with host: String, port:Int) {
                taskQueue.async {
                        do {
                                try self.listenSocket.accept(onInterface: host, port: UInt16(port))
                        } catch {
                                assertionFailure("\(error)")
                        }
                }
        }
        
        func remove(with connection: HTTPConnection) {
                 self.connections.remove(connection)
//                
//                self.listenSocket.delegateQueue!.async {
//                       
//                }
        }
}

extension HttpProxy: GCDAsyncSocketDelegate {
        
        func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
                let conn: HTTPConnection = HTTPConnection(
                        incomingSocket: newSocket
                )
                self.connections.insert(conn)
        }
        
}
