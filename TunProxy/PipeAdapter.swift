//
//  PipeAdapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
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
        
        private var sock:GCDAsyncSocket
        private var tgtHost:String
        private var tgtPort:UInt16
        private var salt:Data
        private var blender:AES
        
        var delegate:GCDAsyncSocketDelegate?
        
        init?(targetHost: String, targetPort: UInt16,
             delegate:GCDAsyncSocketDelegate){
                do {
                        tgtHost = targetHost
                        tgtPort = targetPort
                
                        sock = GCDAsyncSocket(delegate: nil,
                                        delegateQueue: PipeWallet.queue,
                                        socketQueue:PipeWallet.queue)
                        self.delegate = delegate
                
                        let iv: Array<UInt8> = AES.randomIV(AES.blockSize)
                        self.salt = Data.init(iv)
                
                        let aesKey = PipeWallet.shared.AesKey!.bytes
                        self.blender = try AES(key: aesKey, blockMode: CFB.init(iv: iv), padding:.noPadding)
                        
                        super.init()
                        self.sock.synchronouslySetDelegate(self)
                
                        try sock.connect(toHost: PipeWallet.shared.SockSrvIp!,
                                         onPort: PipeWallet.shared.SockSrvPort!)
                } catch let err {
                        NSLog("Open direct adapter err:\(err.localizedDescription)")
                        return nil
                }
        }
}

extension PipeAdapter: GCDAsyncSocketDelegate{
        
        open func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
                NSLog("---PipeAdapter--=>:Pipe Adapter connect to sock5 proxy[\(host):\(port)]")
               
                guard let data = self.handShake() else{
                        self.Close(error: YPError.HandShakeErr)
                        return
                }
                self.sock.write(data, withTimeout: PipeCmdTime,
                                tag: PipeChanState.SynHand.rawValue)
        }
        
        open func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
                
                if tag > PipeChanState.ReadHeaderLen.rawValue{
                        let dataLen = data.ToInt32()
                        guard dataLen != 0 else{
                                NSLog("---PipeAdapter--=>: didRead Protocol err, header len is wrong:\(data.count) data len:\(dataLen)")
                                return
                        }
                        
                        NSLog("---PipeAdapter--=>:Got length header:\(dataLen)")
                        self.sock.readData(toLength: UInt(dataLen),
                                           withTimeout: -1,
                                           tag: tag - PipeChanState.ReadHeaderLen.rawValue)
                        return
                }
                
                guard let cmd = PipeChanState.init(rawValue: tag) else{
                        NSLog("---PipeAdapter--=>:It's read for pipe[\(tag)]")
                        do {
                                NSLog("---PipeAdapter-didRead-\(data.count)=>: before~\(data.toHexString())~")
                                let rawData = try self.blender.decrypt(data.bytes)
                                NSLog("---PipeAdapter-didRead-\(rawData.count)=>: after~\(rawData.toHexString())~")
                                
                                self.delegate?.socket?(sock, didRead: Data.init(rawData), withTag: tag)
                                FlowCounter.shared.Consume(used: data.count)
                        }catch let err{
                                NSLog("---PipeAdapter--=>: read from socks server err:\(err.localizedDescription)")
                        }
                        return
                }
                
                switch cmd {
                        
                case .WaitAck:
                        do{ let json = try JSON(data:data)
                                if let success = json["Success"].bool, !success {
                                        NSLog("---PipeAdapter--=>:Pipe[\(self.tgtHost):\(self.tgtPort)] hand shake err:\(json["Message"] )")
                                        self.Close(error: nil)
                                }
                                NSLog("---PipeAdapter--=>: Create Pipe[\(self.tgtHost):\(self.tgtPort)]  success!")
                                
                                self.sock.write(self.salt,
                                                withTimeout: PipeCmdTime,
                                        tag: PipeChanState.SendSalt.rawValue)
                        }catch let err{
                                NSLog("wait ack data err:\(err.localizedDescription)")
                        }
                        break
                        
                default:
                        NSLog("---PipeAdapter--=>: unknown read cmd[\(cmd)]")
                        break
                }
        }
        
        open func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
                
                guard let cmd = PipeChanState.init(rawValue: tag) else{
                        NSLog("---PipeAdapter--=>:Write success[\(tag)]")
                        self.delegate?.socket?(sock, didWriteDataWithTag: tag)
                        return
                }
                
                switch cmd  {
                case .SynHand:
                        NSLog("---PipeAdapter--=>:Pipe Adapter Send Handshake success")
                        self.sock.readData(withTimeout: 5, tag: PipeChanState.WaitAck.rawValue)
                        break
                        
                case .SendSalt:
                        NSLog("---PipeAdapter--=>:Send salt success")
                        self.delegate?.socket?(self.sock, didConnectToHost: self.tgtHost, port: self.tgtPort)
                        break
                        
                default:
                        NSLog("---PipeAdapter--=>:unknown write tag")
                        break
                }
        }
        
        open func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
                NSLog("---PipeAdapter--=>: pipe close by err:\(err?.localizedDescription ?? "<--->")")
                self.delegate?.socketDidDisconnect?(sock, withError: err)
        }
}

//TODO:: replace this with sorted json
extension PipeAdapter{
        
        func handShake() -> Data?{do{
                
                let request = "{\"Addr\":\"\(PipeWallet.shared.MyAddr!)\",\"Target\":\"\(self.tgtHost):\(self.tgtPort)\"}"
                let data = request.trimmingCharacters(in: CharacterSet.whitespaces).data(using: .utf8)!
                let pk = PipeWallet.shared.priKey!
                let signData =  try NaclSign.signDetached(message: data, secretKey: pk)
                
                let sig = signData.base64EncodedString().replacingOccurrences(of: "\\", with: "")
                let hs = "{\"CmdType\":\(CmdType.CmdPipe.rawValue),\"Sig\": \"\(sig)\", \"Pipe\": \(request)}"
                let hsData = hs.data(using: .utf8)!
                return hsData
                
        }catch let err{
                NSLog("---PipeAdapter--=>:handshake err:\(err.localizedDescription)")
                return nil
        }}
        
        func Close(error:Error?){
                self.delegate?.socketDidDisconnect?(self.sock, withError: error)
        }
}

extension PipeAdapter:Adapter{
        
        func readData(tag: Int) {
                NSLog("---PipeAdapter--=>: read cmd from pipe:[\(tag)]")
                self.sock.readData(toLength: 4,
                                   withTimeout: -1,
                                   tag: tag + PipeChanState.ReadHeaderLen.rawValue)
        }
        
        func write(data: Data, tag: Int) {
                NSLog("---PipeAdapter--=>: write cmd from pipe:[\(tag)]")
                do {
                        NSLog("---PipeAdapter-write-\(data.count)=>: before~\(data.toHexString())~")
                        let cipher = try self.blender.encrypt(data.bytes)
                        
                        let len = UInt32(cipher.count)
                        guard var finalData = len.toData() else{
                                NSLog("---PipeAdapter--=>: This is a empty data")
                                return
                        }
                        finalData.append(Data.init(cipher))
                        NSLog("---PipeAdapter-write-\(finalData.count)=>: after~\(finalData.toHexString())~")
                        
                        self.sock.write(finalData, withTimeout: -1, tag: tag)
                        
                }catch let err{
                        NSLog("---PipeAdapter--=>: Encrypt data to sock server err:\(err.localizedDescription)")
                }
        }
        
        func byePeer() {
                NSLog("---PipeAdapter--=>: closed by peer")
                self.sock.disconnectAfterReadingAndWriting()
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
