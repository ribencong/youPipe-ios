//
//  FlowCounter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/9.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import TweetNacl

class FlowCounter: NSObject{
        
        static let  shared = FlowCounter()
        let queue = DispatchQueue(label: "com.ribencong.flowcounter")
        var totalUsed:Int
        var unsigned:Int
        
        override private init() {
                totalUsed = 0
                unsigned = 0
        }
        
        func Consume(used:Int){
                queue.sync {
                        self.unsigned += used
                }
        }
        
        func PayBill(bill:FlowBill) -> FlowProof {
                return FlowProof()
        }
}

class FlowBill: NSObject{
        
        var SigData:Data
        var Mineral:Data
        var BandWidthInBill:Int64
        var rawData:JSONArray
        
        init(billData:JSONArray) throws{
                self.rawData = billData
                
                guard let minerSig = billData["MinerSig"] as! String? else{
                        throw YPError.InvalidSign
                }
                guard let signature = Data(base64Encoded: minerSig) else{
                        throw YPError.InvalidSign
                }
                self.SigData = signature
                
                guard let id = billData["ID"] as! Int?,
                        let mineTime = billData["MinedTime"] as! String?,
                        let bandwidth = billData["UsedBandWidth"] as! Int64?,
                        let userAddr = billData["ConsumerAddr"] as! String?,
                        let minerAddr = billData["MinerAddr"] as! String? else{
                                throw YPError.InvalidMineral
                }
                self.BandWidthInBill = bandwidth
                
                guard userAddr == PipeWallet.shared.MyAddr else{
                        throw YPError.InvalidMineral
                }
                
                let mineral: JSONArray = [
                        "ID":id,
                        "MinedTime":mineTime,
                        "UsedBandWidth":bandwidth,
                        "ConsumerAddr":userAddr,
                        "MinerAddr":minerAddr,
                ]
                guard let minerData = mineral.ToData() else{
                        throw YPError.InvalidMineral
                }
                self.Mineral = minerData
                
                
                
                
                super.init()
        }
        
        func verify(pubKey:Data) throws ->Bool{
                return  try NaclSign.signDetachedVerify(message: self.Mineral, sig: SigData, publicKey:pubKey)
        }
}

class FlowProof: NSObject{
        override init() {
                super.init()
        }
}
