//
//  DomainCache.swift
//  PacketTunel
//
//  Created by wsli on 2019/5/28.
//  Copyright © 2019 ribencong. All rights reserved.
//

import Foundation
import IosLib
class DomainCache{
        static let shared = DomainCache()
        
        fileprivate var cache: Set<String> = []
        
        init(){
        }
        
        func LoadFromFile(path:URL?){
                guard let p = path else{
                        return
                }
                do {
                        let content = try String(contentsOf: p)
                        let doms = content.components(separatedBy: "\n")
                        for (_, str) in doms.enumerated(){
                                if str == ""{
                                        NSLog("One empty domain")
                                        continue
                                }
                                self.cache.insert(str)
                        }
                        NSLog("Pac domain totalSize:[\(self.cache.count)]")
                }catch let err{
                        NSLog("---=>: Load pac file err\(err.localizedDescription)")
                }
                
        }
        
        func Hit(by:String?) -> Bool{
                guard let h = by else{
                        return false
                }
                
                let domain = IosLibGetDomain(h)
                NSLog("host:[\(h)] domain:[\(domain)]")
                return self.cache.contains(domain)
        }
}
