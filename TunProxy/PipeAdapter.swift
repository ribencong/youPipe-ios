//
//  PipeAdapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class PipeAdapter: Adapter{
        
        private var sock:GCDAsyncSocket
        private var tgtAddr:String
        
        
        init?(targetHost: String, targetPort: UInt16, delegae:GCDAsyncSocketDelegate){
                tgtAddr = "\(targetHost):\(targetPort)"
                
                guard let s = PipeWallet.shared.SetUpPipe() else{
                        return nil
                }
                sock = s
        }
        
        func readData(tag: Int) {
                
        }
        
        func write(data: Data, tag: Int) {
                
        }
        
        func byePeer() {
                
        }
        
        
}
