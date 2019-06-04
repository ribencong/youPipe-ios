//
//  PipeWallet.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class PipeWallet:NSObject{
        static let shared = PipeWallet()
        private override init() {
                super.init()
        }
        
        func Establish(data:String)->Bool{
                return true
        }
        
        func SetUpPipe()->GCDAsyncSocket?{
                return nil
        }
}
