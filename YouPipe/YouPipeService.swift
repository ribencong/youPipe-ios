//
//  YouPipeService.swift
//  YouPipe
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation

let DefaultSeedSever:String = "https://raw.githubusercontent.com/ribencong/ypctorrent/master/ypc.torrent"
//let DefaultSeedSever:String = "https://raw.githubusercontent.com/ribencong/ypctorrent/master/ypc_debug.torrent"
let KEY_FOR_BOOT_NODE_STR = "KEY_FOR_BOOT_NODE_STR"

class YouPipeService:NSObject{
        
        static var shared = YouPipeService()
        var wallet  = WalletParam()
        
        override init() {
                super.init()
        }
        
        func LoadBestBootNode() -> (String, UInt16) {
                let nodes:String? = UserDefaults.standard.string(forKey: KEY_FOR_BOOT_NODE_STR)
                if nodes == nil{
                        
                }
                
                return ("", 80)
        }
}
