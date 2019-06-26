//
//  Tunnel.swift
//  TunProxy
//
//  Created by wsli on 2019/6/3.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import Socket

typealias CloseCallBack = (_ fd: Int32)->Void

public struct HTTPData {
        public static let DoubleCRLF = "\r\n\r\n".data(using: String.Encoding.utf8)!
        public static let CRLF = "\r\n".data(using: String.Encoding.utf8)!
        public static let ConnectSuccessResponse = "HTTP/1.1 200 Connection Established\r\n\r\n".data(using: .utf8)!
}

class Pipe: NSObject{
        
        static let  PipeBufSize:Int         = Int(UInt16.max)
        static let  PipeDefaultTimeOut:UInt = 5
        
        private var targetAddr:String?
        private var targetoPort:Int32?
        
        private var isConnCmd:Bool = false
        private var readStatus:Int = 1
        
        private var proxySock: Socket
        private var adapter: Adapter?
        private var CCB:CloseCallBack?
        
        private var pipeID:Int32
        let queue = DispatchQueue.global(qos: .default)
        
        init(psock:Socket, callBack:@escaping CloseCallBack) {
                
                proxySock = psock
                self.CCB = callBack
                pipeID = psock.socketfd
                super.init()
                queue.async {
                        [unowned self] in
                        self.getRequest()
                }
        }
        
        func getRequest(){
                
                var readBuffer = Data(capacity: Pipe.PipeBufSize)
                defer {
                        NSLog("---Pipe[\(self.pipeID)]---=>client reading exit......")
                        self.breakPipe()
                }
                
                self.readStatus = 1
                
                do{ repeat{
                        let rno = try self.proxySock.read(into: &readBuffer)
                        if rno == 0 {
                                NSLog("---Pipe[\(self.pipeID)]---=>:client read empty data")
                                return
                        }
                        
                        switch self.readStatus {
                        case 1:
                                let header = try HTTPHeader(headerData: readBuffer)
                                NSLog("---Pipe[\(self.pipeID)]---=>:ProxyFirstRequest \(header.toString())......")
                                
                                try self.OpenAdapter(header: header)
                                
                                if self.isConnCmd{
                                        try self.proxySock.write(from: HTTPData.ConnectSuccessResponse)
                                }else{
                                       try self.adapter?.writeData(data: readBuffer.prefix(rno))
                                }
                                
                                self.readStatus = 2
                        break
                        case 2:
                                try self.adapter?.writeData(data: readBuffer.prefix(rno))
                        break
                        default:
                                NSLog("---Pipe[\(self.pipeID)]---=>:unknown reading status:\(self.readStatus)")
                                return
                        }                        
                        readBuffer.count = 0
                        
                }while true }catch let err{
                        NSLog("---Pipe[\(self.pipeID)]---=>:client reading err:\(err.localizedDescription)")
                        return
                }
        }
        
        func OpenAdapter(header:HTTPHeader) throws {

                self.targetAddr = header.host
                self.targetoPort = Int32(header.port)
                self.isConnCmd = header.isConnect
                
                if Domains.shared.Hit(host: header.host){
                        self.adapter = PipeAdapter(targetHost: self.targetAddr!,
                                                   targetPort: self.targetoPort!)
                }else{
                        self.adapter = DirectAdapter(targetHost: self.targetAddr!,
                                                     targetPort: self.targetoPort!)
                }
                guard self.adapter != nil else{
                        throw YPError.HandShakeErr
                }
                self.adapter?.ID = self.pipeID
                NSLog("---Pipe[\(self.pipeID)]---=>:first header:\(header.toString())")
                
                queue.async {
                        [weak self] in
                        self?.waitResponse()
                }
        }
        
        func breakPipe() {
                self.CCB?(self.pipeID)
                self.proxySock.close()
                self.adapter?.byePeer()
        }
        
        
        func waitResponse() {
                
                var readBuffer = Data(capacity: Pipe.PipeBufSize)
                
                defer {
                        NSLog("---Pipe[\(self.pipeID)]---=>server reading exit......")
                        self.breakPipe()
                }
                
                do { repeat{
                        let no = try self.adapter!.readData(into: &readBuffer)
                        if no == 0{
                                NSLog("---Pipe[\(self.pipeID)]---=>: reading from server data finished")
                                return
                        }
                        
                        let wNo = try self.proxySock.write(from: readBuffer)
                        NSLog("---Pipe[\(self.pipeID)]---=>: writing data to client:\(wNo) len:\(no)")
                        
                        readBuffer.count = 0
                        
                }while true } catch let err {
                        NSLog("---Pipe[\(self.pipeID)]---=>:server reading err:\(err.localizedDescription)")
                        return
                }
                
        }
}
