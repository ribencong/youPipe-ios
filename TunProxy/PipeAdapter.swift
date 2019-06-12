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
        let PipeCmdTime:TimeInterval = 5
        let PackLenInBytes  = 4
        //Tips::start from 10000
        public enum PipeChanState:Int{
                case SynHand = 10000,
                WaitAck,
                SendSalt,
                ReadHeaderLen//Tips::should always be the big one in this module
        }
        
        private var sock:Socket
        private var tgtHost:String
        private var tgtPort:Int32
        private var salt:Data
        private var blender:AES
        
        init?(targetHost: String, targetPort: Int32){
                
                do {
                        tgtHost = targetHost
                        tgtPort = targetPort
                
                        self.sock = try Socket.create()
                
                        let iv: Array<UInt8> = AES.randomIV(AES.blockSize)
                        self.salt = Data.init(iv)
                
                        let aesKey = PipeWallet.shared.AesKey!.bytes
                        self.blender = try AES(key: aesKey, blockMode: CFB.init(iv: iv), padding:.noPadding)
                        
                        super.init()
                
                        let host = PipeWallet.shared.SockSrvIp!
                        let port = Int32(PipeWallet.shared.SockSrvPort!)
                        
                        try self.sock.connect(to: host,
                                         port: port,
                                         timeout: 20)
                        
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
                
                let json = try JSON(data:ackBuf)
                if let success = json["Success"].bool, !success {
                        NSLog("---PipeAdapter--=>:Pipe[\(self.tgtHost):\(self.tgtPort)] hand shake err:\(json["Message"] )")
                        self.Close(error: nil)
                }
                
                NSLog("---PipeAdapter--=>: Create Pipe[\(self.tgtHost):\(self.tgtPort)]  success!")
                
                try self.sock.write(from: self.salt)
        }
        
        func handSynData()throws -> Data{
                
                let request = "{\"Addr\":\"\(PipeWallet.shared.MyAddr!)\",\"Target\":\"\(self.tgtHost):\(self.tgtPort)\"}"
                let data = request.trimmingCharacters(in: CharacterSet.whitespaces).data(using: .utf8)!
                let pk = PipeWallet.shared.priKey!
                let signData =  try NaclSign.signDetached(message: data, secretKey: pk)
                
                let sig = signData.base64EncodedString().replacingOccurrences(of: "\\", with: "")
                let hs = "{\"CmdType\":\(CmdType.CmdPipe.rawValue),\"Sig\": \"\(sig)\", \"Pipe\": \(request)}"
                let hsData = hs.data(using: .utf8)!
                return hsData
                
        }
        
        func Close(error:Error?){
                self.sock.close()
        }
}

extension PipeAdapter:Adapter{
        
        func readData() throws -> Data {
                var lenBuf = Data(capacity: 4)
                let _ = try self.sock.read(into: &lenBuf)
                
                let dataLen = lenBuf.ToInt32()
                guard dataLen != 0 && dataLen < Pipe.PipeBufSize else{
                       throw YPError.ReadSocksErr
                }
                
                var dataBuf = Data(capacity: Int(dataLen))
                let _ = try self.sock.read(into: &dataBuf)
                
                NSLog("---PipeAdapter-readData-\(dataBuf.count)=>: before~\(dataBuf.toHexString())~")
                let rawData = try self.blender.decrypt(dataBuf.bytes)
                let finalData = Data.init(rawData)
                NSLog("---PipeAdapter-didRead-\(finalData.count)=>: after~\(finalData.toHexString())~")
                
                FlowCounter.shared.Consume(used: dataBuf.count)
                
                return dataBuf
        }
        
        func writeData(data: Data) throws {
                
                NSLog("---PipeAdapter-writeData-\(data.count)=>: before~\(data.toHexString())~")
                let cipher = try self.blender.encrypt(data.bytes)
                
                let len = UInt32(cipher.count)
                guard var finalData = len.toData() else{
                        NSLog("---PipeAdapter--=>: This is a empty data")
                        throw YPError.EncryptDataErr
                }
                finalData.append(Data.init(cipher))
                NSLog("---PipeAdapter-write-\(finalData.count)=>: after~\(finalData.toHexString())~")
                
                try self.sock.write(from: finalData)
        }
        
        func byePeer() {
                self.Close(error: nil)
        }
        
        
        
}

extension Data{
        public func ToInt32() -> UInt32{
                
                guard self.count == 4 else{
                        return 0
                }
                
                let bytes = self.bytes
                
                return (UInt32(bytes[0]) << 24) +
                       (UInt32(bytes[1]) << 16) +
                       (UInt32(bytes[2]) << 8) +
                       UInt32(bytes[3])
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
