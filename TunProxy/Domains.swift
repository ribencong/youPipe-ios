//
//  Domains.swift
//  TunProxy
//
//  Created by wsli on 2019/6/9.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import DomainParser

class Domains: NSObject {
        static var shared = Domains()
        private var cache:[String] = []
        private var domainParse:DomainParser?
        
        private override init() {
                super.init()
        }
        
        func InitCache(data:[String])throws -> Void {
                self.cache = data
                self.domainParse = try DomainParser() 
        }
        
        func Hit(host:String) -> Bool{
                
                return false
                
//                guard let domain = self.domainParse?.parse(host: host)?.domain else{
//                        return false
//                }
//
//                NSLog("---Domains---=>:domain=\(domain) host=\(host)")
//                return self.cache.contains(domain)
        }
}
