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
        var domainParse:DomainParser?
        private override init() {
                super.init()
        }
        
        func InitCache(data:[String])throws -> Void {
                self.cache = data
                self.domainParse = try DomainParser()
        }
        
        func Hit(host:String) -> Bool{
                
                guard let parsedHost = self.domainParse!.parse(host: host) else{
                        return false
                }
                guard var domain = parsedHost.domain else{
                        return false
                }
                
                if parsedHost.publicSuffix.contains("."){
                        domain = parsedHost.publicSuffix
                }
                
                NSLog("---Domains---=>:domain=\(domain) pubhost=\(parsedHost.publicSuffix) host=\(host)")
                return self.cache.contains(domain)
        }
}
