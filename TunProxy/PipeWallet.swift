//
//  PipeWallet.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import TweetNacl

class FlowCounter: NSObject{
        
        static let  shared = FlowCounter()
        
        var totalUsed:Double
        var unsigned:Double
        
        override private init() {
                totalUsed = 0.0
                unsigned = 0.0
        }
}

class PipeWallet:NSObject{
        static let shared = PipeWallet()
        static let queue = DispatchQueue(label: "com.ribencong.pipeWalletQueue")
        
        public enum PayChanState:Int{
                case SynHand = 1,
                WaitAck,
                WaitBill
        }
        
        var MinerAddr:Data?
        var License:String?
        var priKey:Data?
        var pubKey:Data?
        var aesKey:Data?
        var Eastablished:Bool = false
        
        var PayConn:GCDAsyncSocket?
        
        private override init() {
                super.init()
        }
        
        func Establish(conf:[String:NSObject]) throws{
                
                guard let MinerId = conf["bootID"] as? String else{
                        throw YPError.NoValidBootNode
                }
                self.MinerAddr = Base58.bytesFromBase58(String(MinerId.dropFirst(2)))
                
                guard let ip = conf["bootIP"] as? String,
                        let port = conf["bootPort"] as? UInt16 else{
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
                
                self.License = lic
                self.priKey = pk
                self.aesKey = ak
                
                let (pbk, priData) = try NaclSign.KeyPair.keyPair(fromSecretKey: pk)
                guard priData.elementsEqual(pk) else{
                        throw YPError.OpenPrivateKeyErr
                }
                self.pubKey = pbk
                
                NSLog("must be equal the address of this account YP\(Base58.base58FromBytes(self.pubKey!))")
                
                self.PayConn = GCDAsyncSocket(delegate: self, delegateQueue:
                        PipeWallet.queue, socketQueue: PipeWallet.queue)
        
                try self.PayConn?.connect(toHost: ip, onPort:port, withTimeout:5)
        }
}

extension PipeWallet: GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
                
                do{
                        let d = try self.handShakeData()
                        self.PayConn?.write(d, withTimeout: 5, tag: PayChanState.SynHand.rawValue)
                        
                }catch let err{
                        NSLog("Failed to create payment channel:\(err.localizedDescription)")
                }
        }
        
        open func socketDidDisconnect(_ socket: GCDAsyncSocket, withError err: Error?) {
                self.Close()
                NSLog("---PipeWallet--=>:socketDidDisconnect......\(err.debugDescription)")
        }
        
        open func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
                
                switch (PayChanState.init(rawValue: tag))! {
                case .SynHand:
                        NSLog("Send Sync Handshake success")
                        self.PayConn?.readData(withTimeout: 5, tag: PayChanState.WaitAck.rawValue)
                        break
                default:
                        break
                }
        }
        
        open func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
               
                switch (PayChanState.init(rawValue: tag))! {
                case .WaitAck:
                        let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : Any]
                        let success = json?["Success"] as! Bool
                        if !success{
                                NSLog("pay channel hand shake err:\(json?["Message"] ?? "---")")
                                self.Close()
                        }
                        self.Eastablished = true
                        self.PayConn?.readData(withTimeout: 5, tag: PayChanState.WaitBill.rawValue)
                        break
                        
                case .WaitBill:
                        let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : Any]
                        NSLog("bill:[\(String(describing: json))]")
                        break
                default:
                        break
                }
        }
}


extension PipeWallet{
        
        func handShakeData()throws -> Data{
                
                guard let licData = self.License?.data(using: .utf8) else{
                        throw YPError.NoValidLicense
                }
                
                let sig = try NaclSign.signDetached(message: licData, secretKey: self.priKey!)
                let jsonbody : [String : Any] = [
                        "CmdType" : 1,
                        "Sig":sig,
                        "Lic" : self.License as Any, ]
                
                let data = try JSONSerialization.data(withJSONObject: jsonbody, options: .prettyPrinted)
                return data
        }
        
        func Close(){
                self.PayConn?.disconnectAfterReadingAndWriting()
                self.Eastablished = false
        }
}
