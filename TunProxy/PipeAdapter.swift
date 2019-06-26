//
//  PipeAdapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import Socket
import CryptoSwift
import SwiftyJSON
import TweetNacl

class PipeAdapter: NSObject{
        
        let PackLenInBytes  = 4
        //Tips::start from 10000
        public enum PipeChanState:Int{
                case SynHand = 10000,
                WaitAck,
                SendSalt,
                ReadHeaderLen//Tips::should always be the big one in this module
        }
        
        var ID: Int32?
        private var sock:Socket
        private var tgtHost:String
        private var tgtPort:Int32
        private var salt: Data
        private var aseBlender:AES
        
        let queue = DispatchQueue.global(qos: .default)
        var readingPool = [UInt8](repeating: 0, count: Pipe.PipeBufSize)
        
        init?(targetHost: String, targetPort: Int32){
                do {
                        self.tgtHost = targetHost
                        self.tgtPort = targetPort
                
                        self.sock = try Socket.create(family: .inet, type: .stream, proto: .tcp)
                        let iv = AES.randomIV(AES.blockSize)
                        let aesKey = PipeWallet.shared.AesKey!
                        self.aseBlender = try AES(key: aesKey.bytes, blockMode:CFB(iv: iv), padding: .noPadding)
                        self.salt = Data(bytes: iv)
                        super.init()
                
                        let host = PipeWallet.shared.SockSrvIp!
                        let port = Int32(PipeWallet.shared.SockSrvPort!)
                        
                        try self.sock.connect(to: host, port: port)
                        
                        try self.handShake()
                        
                } catch let err {
                        NSLog("---PipeAdapter--=>:Open Pipe[\(targetHost):\(targetPort))] adapter err:\(err.localizedDescription)")
                        return nil
                }
        }
        
        func handShake()throws{
                
                let syn = try handSynData()
               
                try self.sock.write(from: syn)
                
                var ackBuf = Data(capacity: 1024)
                
                let rno = try self.sock.read(into: &ackBuf)
                
                guard rno > 0 else {
                        NSLog("---PipeAdapter--=>: No hand shake ack")
                        throw YPError.HandShakeErr
                }
                
                let json = try JSON(data:Data(bytes: ackBuf))
                if let success = json["Success"].bool, !success {
                        NSLog("---PipeAdapter--=>:Pipe[\(self.tgtHost):\(self.tgtPort)] hand shake err:\(json["Message"] )")
                        throw YPError.JsonPackError
                }
                
                NSLog("---PipeAdapter--=>: Create Pipe[\(self.tgtHost):\(self.tgtPort)]  success!")
                
                try self.sock.write(from: self.salt)
        }
        
        //TODO::json data parse
        func handSynData()throws -> Data{
                
                let request = "{\"Addr\":\"\(PipeWallet.shared.MyAddr!)\",\"Target\":\"\(self.tgtHost):\(self.tgtPort)\"}"
                let data = request.trimmingCharacters(in: CharacterSet.whitespaces).data(using: .utf8)!
                let pk = PipeWallet.shared.priKey!
                let signData =  try NaclSign.signDetached(message: data, secretKey: pk)
                
                let sig = signData.base64EncodedString().replacingOccurrences(of: "\\", with: "")
                let hs = "{\"CmdType\":\(CmdType.CmdPipe.rawValue),\"Sig\": \"\(sig)\", \"Pipe\": \(request)}"
                return hs.data(using: .utf8)!
                
        }
}

extension PipeAdapter:Adapter{
        
        func readData(into data: inout Data) throws -> Int{
                var lenBuf = [Int8].init(repeating: 0, count: 4)
                var no = try self.sock.read(into: &lenBuf, bufSize: 4, truncate: true)
                if no != 4{
                        NSLog("---PipeAdapter[\(self.ID!)]-too short data:[\(no)]")
                        return 0
                }
                let lenData = Data.init(bytes: lenBuf, count: 4)
                let bodyLen = parseLen(atAddress: lenData)
                
                NSLog("---PipeAdapter[\(self.ID!)]-readData-=>: data length[\(bodyLen)] data:\(data.toHexString())")
                if bodyLen == 0 || bodyLen > Pipe.PipeBufSize{
                        NSLog("---PipeAdapter[\(self.ID!)]---=>: parse body len[\(bodyLen)] failed]")
                        return 0
                }
                
                var bodyBuf = [Int8].init(repeating: 0, count: bodyLen)
               
                no = try self.sock.read(into: &bodyBuf, bufSize: bodyLen, truncate: true)
                NSLog("---PipeAdapter[\(self.ID!)]---=>: read data from pipe server :\(no)]")
                if no > bodyLen{
                        NSLog("---PipeAdapter[\(self.ID!)]---=>: read body data of len[\(bodyLen)] out of range :\(no)]")
                        return 0
                }
                
                var leftDataLen = bodyLen - no
                while leftDataLen > 0 {
                        let newNo = try self.sock.read(into: &bodyBuf + no, bufSize: leftDataLen, truncate: true)
                        no += newNo
                        leftDataLen -= newNo
                }
                
                let cryptData = Data.init(bytes: bodyBuf, count: bodyLen)
                NSLog("---PipeAdapter[\(self.ID!)]-readData-\(cryptData.count)=>: before~\(cryptData.toHexString()))~")
                let rawData = try self.aseBlender.decrypt([UInt8](cryptData))
                data.append(contentsOf: rawData)
                NSLog("---PipeAdapter[\(self.ID!)]-readData-\(data.count)=>: after~\(data.toHexString()))~")
                FlowCounter.shared.Consume(used: bodyLen)
                return bodyLen
        }
        
        func writeData(data: Data) throws {
                
                NSLog("---PipeAdapter[\(self.ID!)]-writeData-\(data.count)=>: before~\(data.toHexString())~")
                var cipher = try self.aseBlender.encrypt(data.bytes)
                let dataLen = UInt32(cipher.count)
                
                guard let lenData = dataLen.toData() else{
                        NSLog("---PipeAdapter[\(self.ID!)]-writeData--invalid cipher data-=>:\(dataLen)")
                        return
                }
                
                cipher.insert(contentsOf: lenData, at: 0)
                
                NSLog("---PipeAdapter[\(self.ID!)]-writeData-\(cipher.count)=>: after~\(cipher.toHexString())~")
                
                try self.sock.write(from: Data(bytes: cipher))
        }
        
        func byePeer() {
                self.sock.close()
        }
        
        func parseLen(atAddress data:Data) -> Int{
              
                guard data.count == 4 else{
                        return 0
                }
                let bytes = [UInt8](data)
                
                return (Int(bytes[0]) << 24) +
                        (Int(bytes[1]) << 16) +
                        (Int(bytes[2]) << 8) +
                        Int(bytes[3])
        }
}

extension UInt32 {
        
        public func toData() -> Data?{
                guard self > 0 else{
                        return nil
                }
                
                let byte1 = UInt8((self >> 24) & 0xFF)
                let byte2 = UInt8((self >> 16) & 0xFF)
                let byte3 = UInt8((self >> 8) & 0xFF)
                let byte4 = UInt8(self & 0xFF)
                
                return Data.init(bytes: [byte1, byte2, byte3, byte4])
        }
}
