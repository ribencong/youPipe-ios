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
                switch (PipeChanState.init(rawValue: tag))! {
                        
                case .WaitAck:
                        let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : Any]
                        let success = json?["Success"] as! Bool
                        if !success{
                                NSLog("---PipeAdapter--=>:Pipe[\(self.tgtHost):\(self.tgtPort)] hand shake err:\(json?["Message"] ?? "---")")
                                self.Close(error: nil)
                        }
                        NSLog("---PipeAdapter--=>: Create Pipe[\(self.tgtHost):\(self.tgtPort)]  success!")
                        
                        self.sock.write(self.salt,
                                        withTimeout: PipeCmdTime,
                                        tag: PipeChanState.SendSalt.rawValue)
                        break
                        
                default:
                        do {
                                let rawData = try self.decryptor.finish(withBytes: data.bytes)
                                self.delegate?.socket?(sock, didRead: Data.init(rawData), withTag: tag)
                                FlowCounter.shared.Consume(used: data.count)
                        }catch let err{
                                NSLog("---PipeAdapter--=>: read from socks server err:\(err.localizedDescription)")
                        }
                        break
                }
        }
        
        open func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
                switch (PipeChanState.init(rawValue: tag))! {
                case .SynHand:
                        NSLog("---PipeAdapter--=>:Pipe Adapter Send Handshake success")
                        self.sock.readData(withTimeout: 5, tag: PipeChanState.WaitAck.rawValue)
                        break
                case .SendSalt:
                        NSLog("---PipeAdapter--=>:Send salt success")
                        self.delegate?.socket?(self.sock, didConnectToHost: self.tgtHost, port: self.tgtPort)
                        break
                default:
                        self.delegate?.socket?(sock, didWriteDataWithTag: tag)
                        break
                }
        }
        
        open func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
                NSLog("---PipeAdapter--=>: pipe close by err:\(err?.localizedDescription ?? "<--->")")
                self.delegate?.socketDidDisconnect?(sock, withError: err)
        }
}

extension PipeAdapter{
        
        func handShake() -> Data?{
                let request : JSONArray = [
                        "Addr":PipeWallet.shared.MyAddr!,
                        "Target":"\(self.tgtHost):\(self.tgtPort)",
                ]
                
                let pk = PipeWallet.shared.priKey!
                let (sig, _) = request.ToSignString(priKey: pk)
                
                let handShake : JSONArray = [
                        "CmdType": CmdType.CmdPipe.rawValue,
                        "Sig":sig as Any,
                        "Pipe":request,
                ]
                
                return handShake.ToData()
        }
        
        func Close(error:Error?){
                self.delegate?.socketDidDisconnect?(self.sock, withError: error)
        }
}

extension PipeAdapter:Adapter{
        
        func readData(tag: Int) {
                self.sock.readData(withTimeout: -1, tag: tag)
        }
        
        func write(data: Data, tag: Int) {
                do {
                        let cipher = try self.encryptor.finish(withBytes: data.bytes)
                        self.sock.write(Data.init(cipher), withTimeout: -1, tag: tag)
                }catch let err{
                        NSLog("Encrypt data to sock server err:\(err.localizedDescription)")
                }
        }
        
        func byePeer() {
        }
        
}
