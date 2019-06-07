//
//  LicenseBean.swift
//  youPipe
//
//  Created by wsli on 2019/6/7.
//  Copyright © 2019年 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import TweetNacl

class LicenseBean:NSObject{
        
        var start:String?
        var end:String?
        var signature:String?
        var userAddr:String?
        var rawData:String
        init?(data:String) {
                self.rawData = data
                super.init()
                do {try parse(RawData: data)}catch{
                        return nil
                }
        }
        
        func parse(RawData data:String) throws{
                let d = data.data(using: String.Encoding.utf8)
                let json = try JSONSerialization.jsonObject(with: d!, options: .allowFragments) as! [String:Any]
                print(json)
                
                self.signature = json["sig"] as? String
                self.start = json["start"] as? String
                self.end = json["end"] as? String
                self.userAddr = json["user"] as? String
        }
        
        func Sign(secretKey:Data)throws ->[UInt8]{
                let data = self.rawData.data(using: .utf8)
                let signData =  try NaclSign.signDetached(message: data!, secretKey: secretKey)
                return [UInt8](signData)
        }
}
