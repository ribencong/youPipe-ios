//
//  TcpProxy.swift
//  TunProxy
//
//  Created by wsli on 2019/6/1.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import NetworkExtension
import ZPTCPIPStack


class TCPProxyServer: NSObject {
        
        static let share = TCPProxyServer()
        
        let server: ZPPacketTunnel
        
        let queue = DispatchQueue(label: "com.ribencong.tcpserver")
     
        override init() {
                self.server = ZPPacketTunnel.shared()
                super.init()
                self.server.setDelegate(
                        self,
                        delegateQueue:queue
                )
        }
}

extension TCPProxyServer: ZPPacketTunnelDelegate {
        
        func tunnel(_ tunnel: ZPPacketTunnel, didEstablishNewTCPConnection conn: ZPTCPConnection) {
                if let _: TCPConnection = TCPConnection(localSocket: conn) {
                       NSLog("New Tcp Connection:")
                }
        }
}
