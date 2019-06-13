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
        var delegate: PipeWriteDelegate
        
        private var sock:Socket
        private var tgtHost:String
        private var tgtPort:Int32
        private var salt:Data
        private var aseBlender:AES
        
        var readingPool = Data(capacity: Pipe.PipeBufSize)
        
        let queue = DispatchQueue(label: "com.ribencong.pipAdapter")
        
        init?(targetHost: String, targetPort: Int32, delegate:PipeWriteDelegate){
                do {
                        self.tgtHost = targetHost
                        self.tgtPort = targetPort
                        self.delegate = delegate
                
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
                        
                        self.queue.async{
                                self.reading()
                        }
                        
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
extension PipeAdapter{
        
        func reading(){
                var tmpBuf = Data(capacity: 1024)
                do{
                        while true{
                                
                                if self.readingPool.count <= 4{
//                                        tmpBuf.removeAll(keepingCapacity: true)
                                        tmpBuf.count = 0
                                        let no = try self.sock.read(into: &tmpBuf)
                                        NSLog("---PipeAdapter[\(self.ID!)]-FillPool start Got---=>:\(no)")
                                        if no < 4 {
                                                NSLog("---PipeAdapter[\(self.ID!)]-too short data:[\(no)]")
                                                return
                                        }
                                        self.readingPool.append(tmpBuf)
                                }
                                
                                let lenData = tmpBuf.dropFirst(4)
                                let bodyLen = lenData.ToInt32()
                                if bodyLen == 0 || bodyLen > Pipe.PipeBufSize{
                                        throw YPError.PipeDataProtocolErr
                                }
                                
                                
                                while self.readingPool.count < bodyLen{
                                        tmpBuf.count = 0
                                        let bodyNO = try self.sock.read(into: &tmpBuf)
                                        NSLog("---PipeAdapter[\(self.ID!)]-FillPool Body Data Got---=>:\(bodyNO)")
                                        self.readingPool.append(tmpBuf)
                                }
                                
                                let data = self.readingPool.dropFirst(bodyLen)
                                NSLog("---PipeAdapter[\(self.ID!)]-FillPool-\(data.count)=>: before~\(data.hexadecimal)~")
                                let rawData = try self.aseBlender.decrypt(data)
                                NSLog("---PipeAdapter[\(self.ID!)]-FillPool-\(rawData.count)=>: after~\(rawData.hexadecimal)~")
                                
                                let _ = try self.delegate.write(rawData: rawData)
                                FlowCounter.shared.Consume(used: rawData.count)
                        }
                        
                }catch let err {
                        
                        NSLog("---PipeAdapter[\(self.ID!)]-FillPool exit---=>:\(err)")
                        return
                }
        }
        
}

extension PipeAdapter:Adapter{
        
        func writeData(data: Data) throws {
                
                NSLog("---PipeAdapter[\(self.ID!)]-writeData-\(data.count)=>: before~\(data.hexadecimal)~")
                var cipher = try self.aseBlender.encrypt(data)
                let dataLen = UInt32(cipher.count)
                
                guard let lenData = dataLen.toData() else{
                        NSLog("---PipeAdapter[\(self.ID!)]-writeData--invalid cipher data-=>:\(dataLen)")
                        return
                }
                
                cipher.insert(contentsOf: lenData, at: 0)
                
                NSLog("---PipeAdapter[\(self.ID!)]-writeData-\(cipher.count)=>: after~\(cipher.hexadecimal)~")
                
                try self.sock.write(from: cipher)
        }
        
        func byePeer() {
                self.Close(error: nil)
        }
}

extension Data{
        public func ToInt32() -> Int{
                NSLog("---PipeAdapter-original->:\(self.hexadecimal)")
                guard self.count == 4 else{
                        return 0
                }
                
                var bytes = [UInt8](self)
                
                return (Int(bytes[0]) << 24) +
                       (Int(bytes[1]) << 16) +
                       (Int(bytes[2]) << 8) +
                       Int(bytes[3])
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
