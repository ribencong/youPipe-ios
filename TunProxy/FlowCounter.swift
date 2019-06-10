//
//  FlowCounter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/9.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import TweetNacl
import SwiftyJSON

class FlowCounter: NSObject{
        
        static let  shared = FlowCounter()
        let queue = DispatchQueue(label: "com.ribencong.flowcounter")
        var totalUsed:Int
        var unsigned:Int
        var PayChannelClosed:Bool
        
        override private init() {
                totalUsed = 0
                unsigned = 0
                PayChannelClosed = false
        }
        
        func Consume(used:Int){
                queue.sync {
                        self.unsigned += used
                }
        }
        
        func CloseCounter(){
                queue.sync {
                        self.PayChannelClosed = true
                }
        }
        
        func SignPayBill(bill:FlowBill) throws-> Data? {
               
               return try queue.sync {
                
                var rawBill = bill.rawData
                if self.PayChannelClosed{
                        throw YPError.PayChannelHasClosed
                }
                
                if self.unsigned < bill.BandWidthInBill{
                        throw YPError.BillOverFlowUsed
                }
                
                let priKey = PipeWallet.shared.priKey!
                let signData =  try NaclSign.signDetached(message: try rawBill.rawData(),
                                                          secretKey: priKey)
                rawBill["ConsumerSig"].string = signData.base64EncodedString()
        
                return try rawBill.rawData()
                }
        }
}

class FlowBill: NSObject{
        
        var SigData:Data
        var Mineral:Data
        var BandWidthInBill:Int64
        var rawData:JSON
        
        init(billData:JSON) throws{
                self.rawData = billData
                
                guard let minerSig = billData["MinerSig"].string else{
                        throw YPError.InvalidSign
                }
                guard let signature = Data(base64Encoded: minerSig) else{
                        throw YPError.InvalidSign
                }
                self.SigData = signature
                
                guard let id = billData["ID"].int,
                        let mineTime = billData["MinedTime"].string,
                        let bandwidth = billData["UsedBandWidth"].int64,
                        let userAddr = billData["ConsumerAddr"].string,
                        let minerAddr = billData["MinerAddr"].string else{
                                throw YPError.InvalidMineral
                }
                self.BandWidthInBill = bandwidth
                
                guard userAddr == PipeWallet.shared.MyAddr else{
                        throw YPError.InvalidMineral
                }
                
                let mineral = JSON( [
                        "ID":id,
                        "MinedTime":mineTime,
                        "UsedBandWidth":bandwidth,
                        "ConsumerAddr":userAddr,
                        "MinerAddr":minerAddr,
                ]) 
                
                self.Mineral = try mineral.rawData()
                super.init()
        }
        
        func verify(pubKey:Data) throws ->Bool{
                return  try NaclSign.signDetachedVerify(message: self.Mineral, sig: SigData, publicKey:pubKey)
        }
}
