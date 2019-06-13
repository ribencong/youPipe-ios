//
//  PipeAdapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import Socket
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
        
        var ID: Int32?
        
        private var sock:Socket
        private var tgtHost:String
        private var tgtPort:Int32
        private var salt:Data
        private var aseBlender:AES
        
        init?(targetHost: String, targetPort: Int32){
                
                do {
                        
                        tgtHost = targetHost
                        tgtPort = targetPort
                
                        self.sock = try Socket.create()
                        self.salt = AES.randomIV()
                        let aesKey = PipeWallet.shared.AesKey!
                        self.aseBlender = try AES(key: aesKey, iv: self.salt)
                        
                        super.init()
                
                        let host = PipeWallet.shared.SockSrvIp!
                        let port = Int32(PipeWallet.shared.SockSrvPort!)
                        
                        try self.sock.connect(to: host,
                                         port: port,
                                         timeout: 120)
                        
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
                
                let lenBuf :UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: 4)
                defer{
                        lenBuf.deallocate()
                }
                
                let _ = try self.sock.read(into: lenBuf, bufSize: 4, truncate: true)
                let dataLen = Data(buffer: UnsafeBufferPointer<CChar>(start: lenBuf, count: 4)).ToInt32()
                NSLog("---PipeAdapter[\(self.ID!)]-readData---=>: Got Header Len:\(dataLen)")
                guard dataLen != 0 && dataLen < Pipe.PipeBufSize else{
                       throw YPError.ReadSocksErr
                }
                
                var dataBuf :UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: Int(dataLen))
                defer{
                        dataBuf.deallocate()
                }
                let _ = try self.sock.read(into: dataBuf, bufSize:  Int(dataLen), truncate:true)
                let data = Data(buffer: UnsafeBufferPointer<CChar>(start: dataBuf, count: Int(dataLen)))
                
                
                NSLog("---PipeAdapter[\(self.ID!)]-readData-\(data.count)=>: before~\(data.hexadecimal)~")
                let rawData = try self.aseBlender.decrypt(data)
                NSLog("---PipeAdapter[\(self.ID!)]-didRead-\(rawData.count)=>: after~\(rawData.hexadecimal)~")
                
                FlowCounter.shared.Consume(used: data.count)
                
                return rawData
        }
        
        func writeData(data: Data) throws {
                
                NSLog("---PipeAdapter[\(self.ID!)]-writeData-\(data.count)=>: before~\(data.hexadecimal)~")
                let cipher = try self.aseBlender.encrypt(data)
                
                let len = UInt32(cipher.count)
                guard var finalData = len.toData() else{
                        NSLog("---PipeAdapter[\(self.ID!)]--=>: This is a empty data")
                        throw YPError.EncryptDataErr
                }
                finalData.append(cipher)
                NSLog("---PipeAdapter[\(self.ID!)]-write-\(finalData.count)=>: after~\(finalData.hexadecimal)~")
                
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
                
                var bytes = [UInt8](self)
                
                return (UInt32(bytes[0]) << 24) +
                       (UInt32(bytes[1]) << 16) +
                       (UInt32(bytes[2]) << 8) +
                       UInt32(bytes[3])
        }
        
        var hexadecimal: String {
                return map { String(format: "%02x", $0) }
                        .joined()
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
