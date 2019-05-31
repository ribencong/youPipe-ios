//
//  PacDomain.swift
//  Tun2Pipe
//
//  Created by wsli on 2019/5/31.
//  Copyright © 2019 ribencong. All rights reserved.
//

import Foundation

class PacDomain {
        static let shared = PacDomain()
        private(set) var cache:[String]
        init() {
                let url = Bundle.main.resourceURL?.appendingPathComponent("gfw.torrent")
                guard let u = url else{
                        NSLog("no doamin list found")
                        exit(EXIT_FAILURE)
                }
                do {
                        let str = try String.init(contentsOf: u).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        self.cache = str.components(separatedBy: ",")
                        NSLog("Size:[\(self.cache.count)]")
//                        for item in self.cache{
//                                NSLog("[\(item)]")
//                        }
                }catch let err{
                        NSLog("parse url to str err:\(err.localizedDescription)")
                        exit(EXIT_FAILURE)
                }
        }
        
        func getTLD(urlString:String) -> String? {
                return urlString
        }
        
        func Hit(host:String?) ->Bool{
                if host == nil{
                        return false
                }
                
                guard let dom = getTLD(urlString: host!) else {
                        return false
                }
                NSLog("host:\(host!) dom:\(dom)")
                return self.cache.contains(dom)
        }
}
