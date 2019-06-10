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
        
        public enum PipeChanState:Int{
                case SynHand = 1,
                WaitAck,
                SendSalt
        }
        
        private var sock:GCDAsyncSocket
        private var tgtHost:String
        private var tgtPort:UInt16
        private var salt:Data
        private var encryptor:(Cryptor & Updatable)
        private var decryptor:(Cryptor & Updatable)
        
        var delegate:GCDAsyncSocketDelegate?
        
        init?(targetHost: String, targetPort: UInt16,
             delegae:GCDAsyncSocketDelegate){
                do {
                        tgtHost = targetHost
                        tgtPort = targetPort
                
                        sock = GCDAsyncSocket(delegate: nil,
                                        delegateQueue: PipeWallet.queue,
                                        socketQueue:PipeWallet.queue)
                        self.delegate = delegae
                
                        let iv: Array<UInt8> = AES.randomIV(AES.blockSize)
                        self.salt = Data.init(iv)
                
                        guard let aesKey = PipeWallet.shared.AesKey?.bytes else{
                                throw YPError.InvalidAesKeyErr
                        }
                
                        let aes = try AES(key: aesKey, blockMode: CFB.init(iv: iv))
                        self.decryptor = try aes.makeDecryptor()
                        self.encryptor = try aes.makeEncryptor()
                
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
                
                guard let cmd = PipeChanState.init(rawValue: tag) else{
                        NSLog("---PipeAdapter--=>:It's read for pipe[\(tag)]")
                        do {
                                let rawData = try self.decryptor.finish(withBytes: data.bytes)
                                self.delegate?.socket?(sock, didRead: Data.init(rawData), withTag: tag)
                                FlowCounter.shared.Consume(used: data.count)
                        }catch let err{
                                NSLog("---PipeAdapter--=>: read from socks server err:\(err.localizedDescription)")
                        }
                        return
                }
                
                switch cmd {
                case .WaitAck:
                        do{
                                let json = try JSON(data:data)
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

struct PipeSig :Codable{
        let Addr:String
        let Target:String
}

struct HandShake:Codable{
        let CmdType:Int
        let Sig:String
        let Pipe:PipeSig
}

extension PipeAdapter{
        
        func handShake() -> Data?{do{
                let encoder = JSONEncoder()
                let request = PipeSig(Addr: PipeWallet.shared.MyAddr!,
                                      Target: "\(self.tgtHost):\(self.tgtPort)")
                
                let data = try encoder.encode(request)
                
                let pk = PipeWallet.shared.priKey!
                let signData =  try NaclSign.signDetached(message: data, secretKey: pk)
                let sig = signData.base64EncodedString()
                
                let hs = HandShake(CmdType: CmdType.CmdPipe.rawValue,
                                   Sig: sig, Pipe: request)
                let hsData = try encoder.encode(hs)
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
                self.sock.readData(withTimeout: -1, tag: tag)
        }
        
        func write(data: Data, tag: Int) {
                NSLog("---PipeAdapter--=>: write cmd from pipe:[\(tag)]")
                do {
                        let cipher = try self.encryptor.finish(withBytes: data.bytes)
                        self.sock.write(Data.init(cipher), withTimeout: -1, tag: tag)
                }catch let err{
                        NSLog("---PipeAdapter--=>: Encrypt data to sock server err:\(err.localizedDescription)")
                }
        }
        
        func byePeer() {
                NSLog("---PipeAdapter--=>: closed by peer")
                self.sock.disconnectAfterReadingAndWriting()
        }
}
