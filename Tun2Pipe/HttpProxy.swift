//
//  HttpProxy.swift
//  Tun2Pipe
//
//  Created by wsli on 2019/5/31.
//  Copyright © 2019 ribencong. All rights reserved.
//

import Foundation
import SwiftSocket

class HttpProxy{
        let PacketQueue = DispatchQueue(label: "com.youpipe.packetqueue", attributes:.concurrent)
        var server:TCPServer
        init(host:String, port:Int32) {
                server = TCPServer(address: host, port: Int32(port))
                PacketQueue.async {
                        self.Accept()
                }
        }
        
        func Accept(){
                switch self.server.listen() {
                case .success:
                        while true {
                                if let client = self.server.accept() {
                                        PacketQueue.async {
                                                self.ProcessProxy(client: client)
                                        }
                                        
                                } else {
                                        NSLog("accept error")
                                        return
                                }
                        }
                case .failure(let error):
                        NSLog(error.localizedDescription)
                        return
                }
        }
        
        
        func ProcessProxy(client: TCPClient) {
                
                NSLog("Newclient from:\(client.address)[\(client.port)]")
                
                let d = client.read(Int(UINT16_MAX))
                
                guard let data = d else{
                        NSLog("read data failed")
                        client.close()
                        return
                }
                
                guard let header =  SimpleHeader(data: data) else {
                        NSLog("Invalid Header")
                        client.close()
                        return
                }
                if PacDomain.shared.Hit(host: header.host){
                        NSLog("Hit success \(String(describing: header.host))")
                }
                
                NSLog("Target:[\(header.host!):\(header.port)]")
        }
}
