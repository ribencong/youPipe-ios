//
//  SimpleHeader.swift
//  Tun2Pipe
//
//  Created by wsli on 2019/5/31.
//  Copyright © 2019 ribencong. All rights reserved.
//

import Foundation
import SwiftSocket


class SimpleHeader{
        let headers: [String]
        init?(data:[Byte]) {
                let str = String.init(bytes: data, encoding: .ascii)
                guard let hds:[String] = str?.components(separatedBy: "\r\n") else{
                        return nil
                }
                self.headers = hds
        }
        
        lazy var requestLine: (method: String, url: String, version: String?)? = {
                guard
                        let comps: [String] = self.headers
                                .first?
                                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                .components(separatedBy: " "),
                        comps.count >= 2
                        else
                {
                        return nil
                }
                if comps.count >= 3 {
                        return (comps[0], comps[1], comps[2])
                } else {
                        return (comps[0], comps[1], nil)
                }
        }()
        
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
        lazy var url: String? = {
                guard let requestLineUrl: String = self.requestLine?.url else {
                        return nil
                }
                if requestLineUrl.hasPrefix("http") {
                        return requestLineUrl
                } else {
//                        if let method: HTTPMethod = self.method,
//                                method == .CONNECT
//                        {
//                                return "https://\(requestLineUrl)"
//                        } else {
                                return "http://\(requestLineUrl)"
//                        }
                }
        }()
        
        var host: String?  {
                if let host: String = self.getHeaderValue(with: "Host:") {
                        /* some host has port e.g. xxx.xxx.xxx:80, so remove the `:Port` */
                        return host.components(separatedBy: ":").first
                } else {
                        return nil
                }
        }
        
        lazy var port: UInt16 = {
                if let urlString: String = self.url,
                        let port: Int = URLComponents(string: urlString)?.port
                {
                        return UInt16(port)
                } else {
                        return 80
                }
        }()
}
