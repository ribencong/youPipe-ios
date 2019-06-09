//
//  Domains.swift
//  TunProxy
//
//  Created by wsli on 2019/6/9.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import TLDExtract


class Domains: NSObject {
        static var shared = Domains()
        private var cache:[String] = []
        private let extractor = try! TLDExtract(useFrozenData: true)
        
        private override init() {
                super.init()
        }
        
        func InitCache(data:[String]) -> Void {
                self.cache = data
        }
        
        func Hit(host:String) -> Bool{
                
                guard let result: TLDResult = extractor.parse(host) else {
                        return false
                }
                
                guard let rootDomian = result.rootDomain else{
                        return false
                }
                
                return self.cache.contains(rootDomian)
        }
}
