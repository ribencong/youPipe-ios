//
//  Domains.swift
//  TunProxy
//
//  Created by wsli on 2019/6/9.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation 

class Domains: NSObject {
        static var shared = Domains()
        private var cache:[String] = []
        
        private override init() {
                super.init()
        }
        
        func InitCache(data:[String])throws -> Void {
                self.cache = data
        }
        
        func Hit(host:String) -> Bool{
                if host.contains("facebook") || host.contains("youtube"){
                        return true
                }
                return false
                
//                guard let domain = self.domainParse?.parse(host: host)?.domain else{
//                        return false
//                }
//
//                NSLog("---Domains---=>:domain=\(domain) host=\(host)")
//                return self.cache.contains(domain)
        }
}
