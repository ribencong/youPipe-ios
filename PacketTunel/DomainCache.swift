//
//  DomainCache.swift
//  PacketTunel
//
//  Created by wsli on 2019/5/28.
//  Copyright © 2019 ribencong. All rights reserved.
//

import Foundation

class DomainCache{
        static let shared = DomainCache()
        
        fileprivate var cache: Set<String> = []
        
        init(){
        }
        
        func LoadFromFile(path:URL){
                
        }
}
