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


class YouPipeService:NSObject{
        
        static var shared = YouPipeService()
        var license:LicenseBean?
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
        
        func LoadLicense() throws -> LicenseBean?{
                guard let licenseStr = UserDefaults.standard.string(forKey: KEY_FOR_YOUPIPE_LICENSE) else{
                        throw YPError.NoValidLicense
                }
                
                self.license = LicenseBean(data: licenseStr)
                return self.license
        }
        
        func ImportLicense(data:String) throws -> LicenseBean?{
                if  IosLibVerifyLicense(data) == false{
                        throw YPError.NoValidLicense
                }
                
                UserDefaults.standard.set(data, forKey: KEY_FOR_YOUPIPE_LICENSE)
                return try LoadLicense()
        }
        
        func PrepareForVpn(password:String) throws -> [String:NSObject]{
                var param:[String:NSObject] = [:]
                
//                let bootNode = try LoadBestBootNode()
               
                let bootNode = "YPBysFiWhobpkFtiw6n1UeUhg8c8stmHJbKWDfad5NhDrZ@@@192.168.103.101:53526"
                
                let idaddr:[String] = bootNode.components(separatedBy: IosLibSeparator)
                guard  idaddr.count == 2 else{
                        throw YPError.NoValidBootNode
                }
                let peerId = idaddr[0]
                let netAddr = idaddr[1]
                
                param["bootID"] = peerId as NSObject
                let ipPort = netAddr.components(separatedBy: ":")
                
                guard ipPort.count == 2 else{
                        throw YPError.NoValidBootNode
                }
                param["bootIP"] = ipPort[0] as NSObject
                param["bootPort"] = UInt16(ipPort[1])! as NSObject
                
                guard let ls = self.license else{
                        throw YPError.NoValidLicense
                }
                param["license"] = ls.rawData as NSObject
                
                guard let addr = self.addr, let cihper = self.cipher else{
                        throw YPError.NoValidAccount
                }
                param["address"] = addr as NSObject
                
                guard let priKey = IosLibGenPriKey(cihper, addr, password) else{
                        throw YPError.OpenPrivateKeyErr
                }
                param["priKey"] = priKey as NSObject
                
                guard let aesKey = IosLibGenAesKey(priKey, peerId) else{
                        throw YPError.OpenPrivateKeyErr
                }
                param["aesKey"] = aesKey as NSObject
                
                return param
        }
}
