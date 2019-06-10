//
//  Common.swift
//  TunProxy
//
//  Created by wsli on 2019/6/8.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import TweetNacl

typealias JSONArray = Dictionary<String, Any>

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any{
        
        func ToData() -> Data?{
                do{
                        let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
                        let cleanStr = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\", with: "")
                        return (cleanStr?.data(using: .utf8))!
                }catch let err{
                        NSLog("JSON Array toData err:\(err.localizedDescription)")
                        return nil
                }
        }
        
        func ToSignString(priKey:Data) -> (String?, Data?){
                guard let data = self.ToData() else{
                        return (nil, nil)
                }
                
                do{
                        let signData =  try NaclSign.signDetached(message: data, secretKey: priKey)
                        return (signData.base64EncodedString(), data)
                }catch{
                        return (nil, nil)
                }
        }
}

public enum CmdType:Int{
        case CmdPayChanel = 2, CmdPipe, CmdCheck
}
