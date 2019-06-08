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
        
        var delegae:GCDAsyncSocketDelegate?
        
        init?(targetHost: String, targetPort: UInt16,
             delegae:GCDAsyncSocketDelegate){
                tgtHost = targetHost
                tgtPort = targetPort
                
                sock = GCDAsyncSocket(delegate: nil,
                                delegateQueue: PipeWallet.queue, socketQueue:PipeWallet.queue)
                self.delegae = delegae
                super.init()
                self.sock.synchronouslySetDelegate(self)
                
                do {
                        try sock.connect(toHost: targetHost,
                                         onPort: targetPort)
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
                        
                        let saltData = self.GenPipeSalt()
                        self.sock.write(saltData,
                                        withTimeout: PipeCmdTime,
                                        tag: PipeChanState.SendSalt.rawValue)
                        break
                        
                default:
                        //TODO::
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
                        self.delegae?.socket?(self.sock, didConnectToHost: self.tgtHost, port: self.tgtPort)
                        break
                default:
                        //TODO::
                        break
                }
        }
}

extension PipeAdapter{
        
        func handShake() -> Data?{
                let request : JSONArray = [
                        "Addr":PipeWallet.shared.Address!,
                        "Target":"\(self.tgtHost):\(self.tgtPort)",
                ]
                
                let pk = PipeWallet.shared.priKey!
                let (sig, _) = request.ToSignString(priKey: pk)
                
                let handShake : JSONArray = [
                        "CmdType": "\(CmdType.CmdPipe)",
                        "Sig":sig as Any,
                        "Pipe":request,
                ]
                
                return handShake.ToData()
        }
        
        func Close(error:Error?){
                self.delegae?.socketDidDisconnect?(self.sock, withError: error)
        }
        
        func GenPipeSalt() ->Data{
                let iv: Array<UInt8> = AES.randomIV(AES.blockSize)
                return Data.init(iv)
        }
}

extension PipeAdapter:Adapter{
        
        func readData(tag: Int) {
                self.sock.readData(withTimeout: -1, tag: tag)
        }
        
        func write(data: Data, tag: Int) {
                self.sock.write(data, withTimeout: -1, tag: tag)
        }
        
        func byePeer() {
        }
        
}
