//
//  PipeWallet.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation 
import TweetNacl
import SwiftyJSON
import Socket

public enum CmdType:Int{
        case CmdPayChanel = 2, CmdPipe, CmdCheck
}

class PipeWallet:NSObject{
        static let shared = PipeWallet()
        let queue = DispatchQueue.global(qos: .default)
        
        public enum PayChanState:Int{
                case SynHand = 1,
                WaitAck,
                WaitBill,
                ProofBill
        }
        
        var MinerAddr:Data?
        var License:LicenseBean?
        var priKey:Data?
        var pubKey:Data?
        var AesKey:Data?
        var MyAddr:String?
        var SockSrvIp:String?
        var SockSrvPort:Int32?
        
        var Eastablished:Bool = false
        
        var PayConn:Socket?
        var ConnectCallBack:((Error?) ->Void)?
        private override init() {
                super.init()
        }
        
        func Establish(conf:[String:NSObject], completionHandler: @escaping (Error?) -> Void) {
                self.ConnectCallBack = completionHandler
                self.TimeOutCheck()
                do {
                        self.PayConn = try Socket.create(family: .inet, type: .stream, proto: .tcp)
                        self.PayConn!.readBufferSize = 1024
                        try Domains.shared.InitCache(data: conf["doamins"] as! [String])
                        try self.connectToServer(conf: conf)
                        
                }catch let err{
                        NSLog("---PipeWallet--=>: Establish err:\(err.localizedDescription)")
                        completionHandler(err)
                }
        }
        
        //TODO::Check the wallet user when payment channel closed
        func Close(){
                self.PayConn?.close()
                self.Eastablished = false
        }
        
        func TimeOutCheck(){
                Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { (kTimer) in
                        self.ConnectCallBack?(YPError.TimeOut)
                        self.ConnectCallBack = nil
                }
        }
}

extension PipeWallet{
        
        func handShakeData()throws -> Data{
                let sig = try self.License!.Sign(secretKey: self.priKey!)
                NSLog("---PipeWallet--=> payment signature:[\(sig)]")
                
                let jsonbody = JSON( [
                        "CmdType" :  CmdType.CmdPayChanel.rawValue,
                        "Sig":sig,
                        "Lic" : [
                                "sig":self.License!.signature!,
                                "start":self.License!.start!,
                                "end":self.License!.end!,
                                "user":self.License!.userAddr!]
                        ])

                return try jsonbody.rawData()
        }
        
        func connectToServer(conf:[String:NSObject]) throws{
                
                guard let MinerId = conf["bootID"] as? String else{
                        throw YPError.NoValidBootNode
                }
                self.MinerAddr = Base58.bytesFromBase58(String(MinerId.dropFirst(2)))
                
                self.MyAddr = conf["address"] as? String
                
                guard let ip = conf["bootIP"] as? String,
                        let port = conf["bootPort"] as? Int32 else{
                                throw YPError.NoValidBootNode
                }
                guard let lic = conf["license"] as? String else{
                        throw YPError.NoValidLicense
                }
                guard let pk = conf["priKey"] as? Data else{
                        throw YPError.OpenPrivateKeyErr
                }
                guard let ak = conf["aesKey"] as? Data else{
                        throw YPError.OpenPrivateKeyErr
                }
                
                self.License = LicenseBean(data: lic)
                self.priKey = pk
                self.AesKey = ak
                
                let (pbk, priData) = try NaclSign.KeyPair.keyPair(fromSecretKey: pk)
                guard priData.elementsEqual(pk) else{
                        throw YPError.OpenPrivateKeyErr
                }
                self.pubKey = pbk
                
                NSLog("---PipeWallet--=>:Connecting to \(ip):\(port)")
                
                self.SockSrvIp = ip
                self.SockSrvPort = port
                try self.PayConn!.connect(to: ip, port: port)
                
                let d = try self.handShakeData()
                try self.PayConn!.write(from: d)
                
                var readBuf = Data(capacity: 1024)
                let no = try self.PayConn!.read(into: &readBuf)
                guard no > 0 else{
                        throw YPError.PaymentChannelErr
                }
                
                let json = try JSON(data:readBuf)
                if let success = json["Success"].bool, !success {
                        NSLog("---PipeWallet--=>:pay channel hand shake err:\(json["Message"] )")
                        throw YPError.PaymentChannelErr
                }
                
                NSLog("---PipeWallet--=>: Create Payment channel success!")
                self.ConnectCallBack?(nil)
                self.Eastablished = true
                
                self.queue.async {
                        self.WaitingBill()
                }
        }
        
        func WaitingBill(){
                
                var readBuf = Data(capacity: 1024)
                defer{
                        self.Close()
                }
                
                do{ repeat{
                        
                        let no = try self.PayConn!.read(into: &readBuf)
                        guard no > 0 else{
                                NSLog("---PipeWallet--=>: read payment bill empty")
                                throw YPError.PaymentChannelErr
                        }
                        
                        let json = try JSON(data:Data(bytes: readBuf))
                        NSLog("---PipeWallet--=>:Got bill:[\(String(describing: json))]")
                        let proofData = try self.SignTheBill(bill:json)
                        try self.PayConn!.write(from: proofData)
                        readBuf.count = 0
                        
                }while self.Eastablished}catch let err{
                        NSLog("---PipeWallet--=>: payment channel close:\(err.localizedDescription)")
                        return
                }
        }
        
        func SignTheBill(bill:JSON) throws -> Data{
                
                let bilObj = try FlowBill(billData: bill)
                
                guard let proof = try FlowCounter.shared.SignPayBill(bill: bilObj) else{
                        throw YPError.SignBillProofErr
                }
                
                return proof
        }
}
