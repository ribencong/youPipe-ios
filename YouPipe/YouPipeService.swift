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
let KEY_FOR_YOUPIPE_DOMAINDATA = "KEY_FOR_YOUPIPE_DOMAINDATA"

let DEFAULT_DOMAIN_DATA_URL = "https://raw.githubusercontent.com/youpipe/ypctorrent/master/gfw.torrent"

let TestData = "1603030e2d0b000e29000e260009b3308209af30820897a003020102020c2cee193c188278ea3e437573300d06092a864886f70d01010b05003066310b300906035504061302424531193017060355040a1310476c6f62616c5369676e206e762d7361313c303a06035504031333476c6f62616c5369676e204f7267616e697a6174696f6e2056616c69646174696f6e204341202d20534841323536202d204732301e170d3139303530393031323230325a170d3230303632353035333130325a3081a7310b300906035504061302434e3110300e060355040813076265696a696e673110300e060355040713076265696a696e6731253023060355040b131c73657276696365206f7065726174696f6e206465706172746d656e7431393037060355040a13304265696a696e67204261696475204e6574636f6d20536369656e636520546563686e6f6c6f677920436f2e2c204c7464311230100603550403130962616964752e636f6d30820122300d06092a864886f70d01010105000382010f003082010a0282010100b4c6bfda53200fea40f3b85217663b36018d12b4990dd39b6c1853b11908b0fa73473e0d3a796278612e543c497c56dac0be6155d542706a10bef5bd8d6496210093630987b719ba0e203e49c853ed028f4601eba1079373bbedf1b3c9e2fbddf0392a83adf44198bc86eaba74a8a6e3d0e5c58eb30bb2d2ac91740eff80102336626508b487f5570c25c700d8f5a85db83341a72a5fdbfa709e21bbae4216660769fe1c262a810fab73e3d65220a46da86cd46648a46ff2680ac565a14ebf047a40431cd375fb75ac19d64a35056ecfd565d144ca6b0c5804c4854f1fbe2c32d1f1c628fbf92636b56dfacb96a2a0d0bcf851df0744bd8f6f67c0d4afd9cdc30203010001a382061930820615300e0603551d0f0101ff0404030205a03081a006082b06010505070101048193308190304d06082b060105050730028641687474703a2f2f7365637572652e676c6f62616c7369676e2e636f6d2f6361636572742f67736f7267616e697a6174696f6e76616c73686132673272312e637274303f06082b060105050730018633687474703a2f2f6f637370322e676c6f62616c7369676e2e636f6d2f67736f7267616e697a6174696f6e76616c73686132673230560603551d20044f304d304106092b06010401a03201143034303206082b06010505070201162668747470733a2f2f7777772e676c6f62616c7369676e2e636f6d2f7265706f7369746f72792f3008060667810c01020230090603551d130402300030490603551d1f04423040303ea03ca03a8638687474703a2f2f63726c2e676c6f62616c7369676e2e636f6d2f67732f67736f7267616e697a6174696f6e76616c7368613267322e63726c308203490603551d11048203403082033c820962616964752e636f6d8212636c69636b2e686d2e62616964752e636f6d8210636d2e706f732e62616964752e636f6d82106c6f672e686d2e62616964752e636f6d82147570646174652e70616e2e62616964752e636f6d8210776e2e706f732e62616964752e636f6d82082a2e39312e636f6d820b2a2e6169706167652e636e820c2a2e6169706167652e636f6d820d2a2e61706f6c6c6f2e6175746f820b2a2e62616964752e636f6d820e2a2e62616964756263652e636f6d82122a2e6261696475636f6e74656e742e636f6d820e2a2e62616964757063732e636f6d82112a2e62616964757374617469632e636f6d820c2a2e6261696661652e636f6d820e2a2e626169667562616f2e636f6d820f2a2e6263652e62616964752e636f6d820d2a2e626365686f73742e636f6d820b2a2e6264696d672e636f6d820e2a2e62647374617469632e636f6d820d2a2e6264746a7263762e636f6d82112a2e626a2e62616964756263652e636f6d820d2a2e636875616e6b652e636f6d820b2a2e646c6e656c2e636f6d820b2a2e646c6e656c2e6f726782122a2e647565726f732e62616964752e636f6d82102a2e6579756e2e62616964752e636f6d82112a2e66616e79692e62616964752e636f6d82112a2e677a2e62616964756263652e636f6d82122a2e68616f3132332e62616964752e636f6d820c2a2e68616f3132332e636f6d820c2a2e68616f3232322e636f6d820e2a2e696d2e62616964752e636f6d820f2a2e6d61702e62616964752e636f6d820f2a2e6d62642e62616964752e636f6d820c2a2e6d697063646e2e636f6d82102a2e6e6577732e62616964752e636f6d820b2a2e6e756f6d692e636f6d82102a2e736166652e62616964752e636f6d820e2a2e736d617274617070732e636e82112a2e73736c322e6475617070732e636f6d820e2a2e73752e62616964752e636f6d820d2a2e7472757374676f2e636f6d82122a2e7875657368752e62616964752e636f6d820b61706f6c6c6f2e6175746f820a6261696661652e636f6d820c626169667562616f2e636f6d820664777a2e636e820f6d63742e792e6e756f6d692e636f6d820c7777772e62616964752e636e82107777772e62616964752e636f6d2e636e301d0603551d250416301406082b0601050507030106082b06010505070302301d0603551d0e0416041476b5e6d649f8f836ea75a96d5e4d555b375cfdc7301f0603551d2304183016801496de61f1bd1c1629531cc0cc7d3b830040e61a7c30820104060a2b06010401d6790204020481f50481f200f0007600bbd9dfbc1f8a71b593942397aa927b473857950aab52e81a909664368e1ed1850000016a9a2ee19a000004030047304502202c7b4dc0f985478a2d0ac0793bd6b4b566f8aafb8258ad2336fe16bca6839921022100c02fcd9c9920cb7d915fd28bc6131073b5c1540333419fa66ac51493cf692b6b0076006f5376ac31f03119d89900a45115ff77151c11d902c10029068db2089a37d9130000016a9a2ede4f000004030047304502200332689e39d0eb5f1961dba712696f28448102a53cc2a313d57e98265f201aa0022100a78b62b3b0b44432e211ff458d55112c36ab299344c8345cce7c355731aeab12300d06092a864886f70d01010b05000382010100aab9cd528edc365d47d48bf3321706468360a327054929b11b466e38fe93fe09436cd2a158241242b7ab41f8470a7d64b575dc5a4514b2a4186b9cb73b8fb37ed2bdc0724b3505ae0d2d191f5073725adf97183bdb2af3de44ce642dc11e84cc76243e30672326e84ff70bf6ec69d77f51a9a06fb8c414e2c04a4ac4005d576ac941c4252b3218aa62a81e4981731c815f5efae49432c3506d8eaacc6c4c530cfa8f4e34799fa560c0f85075b8a19d01e6ab25230c3b2402405824ff34028b946110682fb680e3d05f4a0aa702d2c0983e1de802c8277126b2a887b6db9d10474bc2136234c6d03c390939258ffea2f4f3fbdf9b273dfcd028e86ddcdd17d31f00046d3082046930820351a003020102020b040000000001444ef04247300d06092a864886f70d01010b05003057310b300906035504061302424531193017060355040a1310476c6f62616c5369676e206e762d73613110300e060355040b1307526f6f74204341311b301906035504031312476c6f62616c5369676e20526f6f74204341301e170d3134303232303130303030305a170d3234303232303130303030305a3066310b300906035504061302424531193017060355040a1310476c6f62616c5369676e206e762d7361313c303a06035504031333476c6f62616c5369676e204f7267616e697a6174696f6e2056616c69646174696f6e204341202d20534841323536202d20473230820122300d06092a864886f70d01010105000382010f003082010a0282010100c70e6c3f23937fcc70a59d20c30e533f7ec04ec29849ca47d523ef03348574c8a3022e465c0b7dc9889d4f8bf0f89c6c8c5535dbbff2b3eafbe356e74a46d91322ca36d59bc1a8e3964393f20cbce6f9e6e899c86348787f5736691a191d5ad1d47dc29cd47fe18012ae7aea88ea57d8ca0a0a3a1249a262"

let TestData2 = "16030300550200005103035d0232bd69a3b1022e2ac4e73e52f30e2c931c28f2d201e4ee21ebdd501eb685207cc37c0c36c2dc1f94b1399ff4cf86c4c3cb587e527104bbb431b6a0f612968ac02f000009001000050003026832"

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
        
        func LoadDomain() throws ->[String]{
                
                var domainStr:String? = UserDefaults.standard.string(forKey: KEY_FOR_YOUPIPE_DOMAINDATA)
                if domainStr == nil{
                        domainStr = IosLibLoadDomain(DEFAULT_DOMAIN_DATA_URL)
                        UserDefaults.standard.set(domainStr, forKey: KEY_FOR_YOUPIPE_DOMAINDATA)
                }
                guard let domains = domainStr?.components(separatedBy: ","),
                        domains.count > 0 else {
                                throw YPError.NoDomains
                }
                return domains
        }
        
        func PrepareForVpn(password:String) throws -> [String:NSObject]{
                var param:[String:NSObject] = [:]
                
//                let bootNode = try LoadBestBootNode()
               
//                let bootNode = "YPBzFaBFv8ZjkPQxtozNQe1c9CvrGXYg4tytuWjo9jiaZx@@@192.168.1.108:61948"
                //TODO:: Tmp test
//                let bootNode = "YPBysFiWhobpkFtiw6n1UeUhg8c8stmHJbKWDfad5NhDrZ@@@192.168.103.101:53526"
                
//                let bootNode = "YPBzFaBFv8ZjkPQxtozNQe1c9CvrGXYg4tytuWjo9jiaZx@@@192.168.107.72:61948"
                let bootNode = "YPBzFaBFv8ZjkPQxtozNQe1c9CvrGXYg4tytuWjo9jiaZx@@@192.168.30.12:61948"
                
                
                let domains = try LoadDomain()
                param["doamins"] = domains as NSObject
                
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
                param["bootPort"] = Int32(ipPort[1])! as NSObject
                
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
                let salt = AES.randomIV()
                let aes = try AES.init(key: aesKey, iv: salt)
                
                
                let digest = TestData.hexadecimal!
                let enData = IosLibTestAes(aesKey, salt, digest)!
                print("\(enData.hexadecimal)")
                let deData = try aes.decrypt(enData)
                print("我来解码：\(deData.hexadecimal)")
                
                
                
                let digest2 = TestData2.hexadecimal!
                let enData2 = IosLibTestAes(aesKey, salt, digest2)!
                print("\(enData2.hexadecimal)")
                let deData2 = try aes.decrypt(enData2)
                print("我来解码：\(deData2.hexadecimal)")
                
                
                return param
        }
        
        
}

extension Data{
        var hexadecimal: String {
                return map { String(format: "%02x", $0) }
                        .joined()
        }
}
extension String {
        var hexadecimal: Data? {
                var data = Data(capacity: characters.count / 2)
                
                let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
                regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
                        let byteString = (self as NSString).substring(with: match!.range)
                        let num = UInt8(byteString, radix: 16)!
                        data.append(num)
                }
                
                guard data.count > 0 else { return nil }
                
                return data
        }
        
}
