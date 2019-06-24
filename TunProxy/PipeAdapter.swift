//
//  PipeAdapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
//import Socket
import CryptoSwift
import SocketSwift
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
        var delegate: PipeWriteDelegate
        
        private var sock:Socket
        private var tgtHost:String
        private var tgtPort:Int32
        private var salt:[UInt8]
        private var aseBlender:AES
        
        var readingPool = [UInt8](repeating: 0, count: Pipe.PipeBufSize)
        
        let queue = DispatchQueue(label: "com.ribencong.pipAdapter")
        
        init?(targetHost: String, targetPort: Int32, delegate:PipeWriteDelegate){
                do {
                        self.tgtHost = targetHost
                        self.tgtPort = targetPort
                        self.delegate = delegate
                
                        self.sock = try Socket(.inet, type: .stream, protocol: .tcp)
                        self.salt = AES.randomIV(AES.blockSize)
                        let aesKey = PipeWallet.shared.AesKey!
                        self.aseBlender = try AES(key: aesKey.bytes, blockMode:CFB(iv: self.salt), padding: .noPadding)
                        
                        super.init()
                
                        let host = PipeWallet.shared.SockSrvIp!
                        let port = Int32(PipeWallet.shared.SockSrvPort!)
                        
                        try self.sock.connect(port: Port(port), address: host)
                        
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
               
                try self.sock.write(syn)
                
                var ackBuf = [UInt8](repeating: 0, count: 1024)
                
                let rno = try self.sock.read(&ackBuf, size: 1024)
                
                guard rno > 0 else {
                        NSLog("---PipeAdapter--=>: No hand shake ack")
                        throw YPError.HandShakeErr
                }
                
                let json = try JSON(data:Data(bytes: ackBuf))
                if let success = json["Success"].bool, !success {
                        NSLog("---PipeAdapter--=>:Pipe[\(self.tgtHost):\(self.tgtPort)] hand shake err:\(json["Message"] )")
                        self.Close(error: nil)
                }
                
                NSLog("---PipeAdapter--=>: Create Pipe[\(self.tgtHost):\(self.tgtPort)]  success!")
                
                try self.sock.write([UInt8](self.salt))
        }
        
        func handSynData()throws -> [UInt8]{
                
                let request = "{\"Addr\":\"\(PipeWallet.shared.MyAddr!)\",\"Target\":\"\(self.tgtHost):\(self.tgtPort)\"}"
                let data = request.trimmingCharacters(in: CharacterSet.whitespaces).data(using: .utf8)!
                let pk = PipeWallet.shared.priKey!
                let signData =  try NaclSign.signDetached(message: data, secretKey: pk)
                
                let sig = signData.base64EncodedString().replacingOccurrences(of: "\\", with: "")
                let hs = "{\"CmdType\":\(CmdType.CmdPipe.rawValue),\"Sig\": \"\(sig)\", \"Pipe\": \(request)}"
                return [UInt8](hs.utf8)
                
        }
        
        func Close(error:Error?){
                self.sock.close()
        }
}
extension PipeAdapter{
        
        func reading(){
                var tmpBuf = [UInt8](repeating: 0, count: 4)
                do{
                        while true{
                                
                                if self.readingPool.count <= 4{
                                        tmpBuf.removeAll(keepingCapacity: true)
                                        
                                        let no = try self.sock.read(&tmpBuf, size: 4)
                                        NSLog("---PipeAdapter[\(self.ID!)]-FillPool start Got---=>:\(no)")
                                        if no < 4 {
                                                NSLog("---PipeAdapter[\(self.ID!)]-too short data:[\(no)]")
                                                return
                                        }
                                        self.readingPool += tmpBuf//.append(contentsOf:tmpBuf)
                                }
                                
                                let lenData = Array(self.readingPool.prefix(4))
                                let bodyLen = lenData.ToInt32()
                                if bodyLen == 0 || bodyLen > Pipe.PipeBufSize{
                                        NSLog("---PipeAdapter[\(self.ID!)]-invalid data lenght [\(bodyLen)]   data:[\(lenData.toHexString())]")
                                        throw YPError.PipeDataProtocolErr
                                }
                                
                                NSLog("--PipeAdapter[\(self.ID!)]-FillPool body length is \(bodyLen) ")
                                
                                self.readingPool.removeFirst(4)
                                while self.readingPool.count < bodyLen{
                                        tmpBuf.removeAll()
                                        let bodyNO = try self.sock.read(&tmpBuf, size: 4)
                                        NSLog("---PipeAdapter[\(self.ID!)]-FillPool Body Data Got---=>:\(bodyNO)")
                                        self.readingPool += tmpBuf //.append(contentsOf:tmpBuf)
                                }
                                
                                let data = Array(self.readingPool.prefix(bodyLen))
                                NSLog("---PipeAdapter[\(self.ID!)]-FillPool-\(data.count)=>: before~\(data.toHexString()))~")
                                let rawData = try self.aseBlender.decrypt(data)
                                NSLog("---PipeAdapter[\(self.ID!)]-FillPool-\(rawData.count)=>: after~\(rawData.toHexString()))~")
                                
                                let _ = try self.delegate.write(rawData: rawData)
                                self.readingPool.removeFirst(bodyLen)
                                FlowCounter.shared.Consume(used: rawData.count)
                        }
                        
                }catch let err {
                        NSLog("---PipeAdapter[\(self.ID!)]-FillPool exit---=>:\(err.localizedDescription)")
                        return
                }
        }
        
}

extension PipeAdapter:Adapter{
        
        func writeData(data: [UInt8]) throws {
                
                NSLog("---PipeAdapter[\(self.ID!)]-writeData-\(data.count)=>: before~\(data.toHexString())~")
                var cipher = try self.aseBlender.encrypt(data)
                let dataLen = UInt32(cipher.count)
                
                guard let lenData = dataLen.toData() else{
                        NSLog("---PipeAdapter[\(self.ID!)]-writeData--invalid cipher data-=>:\(dataLen)")
                        return
                }
                
                cipher.insert(contentsOf: lenData, at: 0)
                
                NSLog("---PipeAdapter[\(self.ID!)]-writeData-\(cipher.count)=>: after~\(cipher.toHexString())~")
                
                try self.sock.write(cipher)
        }
        
        func byePeer() {
                self.Close(error: nil)
        }
}

extension Array where Element == UInt8{
        public func ToInt32() -> Int{
                guard self.count == 4 else{
                        return 0
                }
                
                var bytes = [UInt8](self)
                
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
