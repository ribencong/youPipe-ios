//
//  PipeAdapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class PipeAdapter: NSObject, Adapter{
        
        private var sock:GCDAsyncSocket
        private var tgtAddr:String
        
        
        init(targetHost: String, targetPort: UInt16, delegae:GCDAsyncSocketDelegate){
                tgtAddr = "\(targetHost):\(targetPort)"
                
                sock = GCDAsyncSocket(delegate: nil,
                                delegateQueue: PipeWallet.queue, socketQueue:PipeWallet.queue)
                super.init()
                sock.synchronouslySetDelegate(self)
        }
        
        func readData(tag: Int) {
                
        }
        
        func write(data: Data, tag: Int) {
                
        }
        
        func byePeer() {
                
        }
}

extension PipeAdapter: GCDAsyncSocketDelegate{
        open func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
                
        }
}
