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
        
        init?(localSocket: ZPTCPConnection){
                self.local = localSocket
                self.remote = GCDAsyncSocket()
                super.init()
        }
}
