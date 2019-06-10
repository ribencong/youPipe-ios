//
//  LicenseBean.swift
//  youPipe
//
//  Created by wsli on 2019/6/7.
//  Copyright © 2019年 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import TweetNacl
import SwiftyJSON

class LicenseBean:NSObject{
        
        var start:String?
        var end:String?
        var signature:String?
        var userAddr:String?
        var rawData:String
        init(data:String) {
                self.rawData = data
                print(data)
                super.init()
                parse(RawData: data)
        }
        
        func parse(RawData data:String){
                let json = JSON(parseJSON: data)
                print(json)
                
                self.signature = json["sig"].string
                self.start = json["start"].string
                self.end = json["end"].string
                self.userAddr = json["user"].string
        }
        
        func Sign(secretKey:Data)throws ->String{
                let data = self.rawData.data(using: .utf8)
                let signData =  try NaclSign.signDetached(message: data!, secretKey: secretKey)
                return signData.base64EncodedString()
        }
}
