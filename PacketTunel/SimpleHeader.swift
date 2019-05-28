//
//  SimpleHeader.swift
//  PacketTunel
//
//  Created by wsli on 2019/5/28.
//  Copyright © 2019 ribencong. All rights reserved.
//

import Foundation

class SimpleHttpHeader{
        
        let headers: [String]
        
        var method: HTTPMethod? = HTTPMethod(rawValue: "Get")
        var url:String?=""
        var port:Int = 80
        var host:String?=""
        
        init(headStr: String){
                self.headers = headStr.components(separatedBy: "\r\n")
                guard self.headers.count >= 2 else {
                        return
                }
                
                let require = self.headers.first?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let cmds = require!.components(separatedBy: " ")
//                NSLog("require \(require!) cmd1:\(cmds[0]) cmd2:\(cmds[1]) ")
                
                self.method = HTTPMethod(rawValue: cmds[0])
                self.url = cmds[1]
                let uris = self.url?.components(separatedBy: ":")
                if uris?.count != 2{
                        self.port = 80
                }else{
                        self.port = Int(uris![1]) ?? 80
                }
                
                self.host = getHeaderValue(with: "Host:")
        }
        
        func getHeaderValue(with key: String) -> String? {
                for item in self.headers {
                        if item.hasPrefix(key) {
                                let value: String = item.replacingOccurrences(
                                        of: key,
                                        with: "",
                                        options: [.anchored, .caseInsensitive],
                                        range: item.startIndex..<item.endIndex
                                )
                                return value.trimmingCharacters(
                                        in: CharacterSet.whitespacesAndNewlines
                                )
                        }
                }
                return nil
        }
}
