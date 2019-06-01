//
//  TCPConnection.swift
//  TunProxy
//
//  Created by wsli on 2019/6/1.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import ZPTCPIPStack

class TCPConnection:NSObject{
        
        let local: ZPTCPConnection
        
        let remote: GCDAsyncSocket
        static var connections: Set<TCPConnection> = []
        
        let queue = DispatchQueue(label: "com.ribencong.tcpserver", attributes:.concurrent)
        init?(localSocket: ZPTCPConnection){
                self.local = localSocket
                self.remote = GCDAsyncSocket()
                super.init()
                TCPConnection.connections.insert(self)
                
                if !self.local.syncSetDelegate(self, delegateQueue: queue) {
                        self.close(with: "Local TCP has aborted before connecting remote.")
                        return nil
                }
                self.remote.synchronouslySetDelegate(
                        self,
                        delegateQueue: queue
                )
        }
        
        func close(with note: String) {
                
                /* close connection */
                self.local.closeAfterWriting()
                self.remote.disconnectAfterWriting()
                
                if let success = TCPConnection.connections.remove(self){
                        NSLog("Remove Connection success:\(success)")
                }
        }
}


extension TCPConnection: ZPTCPConnectionDelegate {
        
        func connection(_ connection: ZPTCPConnection, didRead data: Data) {
                self.remote.write(
                        data,
                        withTimeout: 5,
                        tag: data.count
                )
                
        }
        
        func connection(_ connection: ZPTCPConnection, didWriteData length: UInt16, sendBuf isEmpty: Bool) {
                
                if isEmpty {
                        self.remote.readData(
                                withTimeout: -1,
                                buffer: nil,
                                bufferOffset: 0,
                                maxLength: UInt(UINT16_MAX / 2),
                                tag: 0
                        )
                }
                
        }
        
        func connection(_ connection: ZPTCPConnection, didCheckWriteDataWithError err: Error) {
                self.close(with: "Local write: \(err)")
        }
        
        func connection(_ connection: ZPTCPConnection, didDisconnectWithError err: Error) {
                self.close(with: "Local: \(err)")
        }
        
}

extension TCPConnection: GCDAsyncSocketDelegate {
        
        func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
                
                self.local.readData()
                self.remote.readData(
                        withTimeout: -1,
                        buffer: nil,
                        bufferOffset: 0,
                        maxLength: UInt(UINT16_MAX / 2),
                        tag: 0
                )
        }
        
        func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
                self.local.write(data)
        }
        
        func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
                self.local.readData()
        }
        
        func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
                self.close(with: "Remote: \(String(describing: err))")
        }
}
