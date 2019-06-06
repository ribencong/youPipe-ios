//
//  YouPipeService.swift
//  YouPipe
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import IosLib 

let KEY_FOR_BOOT_NODE_STR = "KEY_FOR_BOOT_NODE_STR"
let KEY_FOR_BLOOK_CHAIN_ADDR = "KEY_FOR_BLOOK_CHAIN_ADDR"
let KEY_FOR_BLOOK_CHAIN_CIPHER = "KEY_FOR_BLOOK_CHAIN_CIPHER"
let KEY_FOR_YOUPIPE_LICENSE = "KEY_FOR_YOUPIPE_LICENSE"

class WalletParam: NSObject{
        var Addr:String?
        var Cipher:String?
        var License:String?
        var bootAddr:String?
        var bootPort:String?
        
        override init() {
                super.init()
        }
}

class LicenseObj:NSObject{
        
        var start:String?
        var end:String?
        var signature:String?
        var userAddr:String?
        var rawStr:String
        init?(data:String) {
                rawStr = data
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
}

class YouPipeService:NSObject{
        
        static var shared = YouPipeService()
        var wallet  = WalletParam()
        var license:LicenseObj?
        var addr:String?
        var cipher:String?
        
        override private init() {
                super.init()
        }
        
        func LoadBestBootNode() throws -> String{
                var nodeStr:String? = UserDefaults.standard.string(forKey: KEY_FOR_BOOT_NODE_STR)
                if nodeStr == nil{
                        nodeStr = IosLibLoadNodes()
                        UserDefaults.standard.set(nodeStr, forKey: KEY_FOR_BOOT_NODE_STR)
                }
                
                let bootNode = IosLibFindBestNode(nodeStr)
                if bootNode == ""{
                        throw YPError.NoValidBootNode
                }
                return bootNode
        }
        
        func LoadBlockChainAccount() throws -> (String, String){
                guard let addr = UserDefaults.standard.string(forKey: KEY_FOR_BLOOK_CHAIN_ADDR) else{
                       throw YPError.NoValidAccount
                }
                
                guard let cipher = UserDefaults.standard.string(forKey: KEY_FOR_BLOOK_CHAIN_CIPHER) else{
                        throw YPError.NoValidAccount
                }
                self.addr = addr
                self.cipher = cipher
                return (addr, cipher)
        }
        
        func CreateAccount(password:String) throws -> (String, String){
                
                let accountInfo = IosLibCreateAccount(password)
                let acc:[String] = accountInfo.components(separatedBy: "@@@")
                if acc.count != 2 {
                        throw YPError.AccountCreateError
                }
                
                UserDefaults.standard.set(acc[0], forKey: KEY_FOR_BLOOK_CHAIN_ADDR)
                UserDefaults.standard.set(acc[1], forKey: KEY_FOR_BLOOK_CHAIN_CIPHER)
                self.addr = acc[0]
                self.cipher = acc[1]
                return (acc[0], acc[1])
        }
        
        func LoadLicense() throws -> LicenseObj?{
                guard let licenseStr = UserDefaults.standard.string(forKey: KEY_FOR_YOUPIPE_LICENSE) else{
                        throw YPError.NoValidLicense
                }
                
                self.license = LicenseObj(data: licenseStr)
                return self.license
        }
        
        func ImportLicense(data:String) throws -> LicenseObj?{
                if  IosLibVerifyLicense(data) == false{
                        throw YPError.NoValidLicense
                }
                
                UserDefaults.standard.set(data, forKey: KEY_FOR_YOUPIPE_LICENSE)
                return try LoadLicense()
        }
        
        func PrepareForVpn(password:String) throws -> [String:String]{
                var param:[String:String] = [:]
                
                let bootNode = try LoadBestBootNode()
               
                let idaddr:[String] = bootNode.components(separatedBy: IosLibSeparator)
                guard  idaddr.count == 2 else{
                        throw YPError.NoValidBootNode
                }
                let peerId = idaddr[0]
                let netAddr = idaddr[1]
                
                param["bootID"] = peerId
                let ipPort = netAddr.components(separatedBy: ":")
                
                guard ipPort.count == 2 else{
                        throw YPError.NoValidBootNode
                }
                param["bootIP"] = ipPort[0]
                param["bootPort"] = ipPort[1]
                
                guard let ls = self.license else{
                        throw YPError.NoValidLicense
                }
                param["license"] = ls.rawStr
                
                guard let addr = self.addr, let cihper = self.cipher else{
                        throw YPError.NoValidAccount
                }
                param["address"] = addr
                
                let signAndKey = IosLibSigWithKey(cihper, addr, password, ls.rawStr, peerId)
                let sd = signAndKey.components(separatedBy:IosLibSeparator)
                guard sd.count == 2 else{
                        throw YPError.OpenPrivateKeyErr
                }
                
                param["licSig"] = sd[0]
                param["aesKey"] = sd[1]
                
                return param
        }
}
