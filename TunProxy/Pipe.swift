//
//  Tunnel.swift
//  TunProxy
//
//  Created by wsli on 2019/6/3.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import Socket

typealias CloseCallBack = ()->Void

public struct HTTPData {
        public static let DoubleCRLF = "\r\n\r\n".data(using: String.Encoding.utf8)!
        public static let CRLF = "\r\n".data(using: String.Encoding.utf8)!
        public static let ConnectSuccessResponse = "HTTP/1.1 200 Connection Established\r\n\r\n".data(using: String.Encoding.utf8)!
}

class Pipe: NSObject{
        
        static let  PipeBufSize:Int         = Int(UINT16_MAX)
        static let  PipeDefaultTimeOut:UInt = 5
        
        private var targetAddr:String?
        private var targetoPort:Int32?
        
        private var isConnCmd:Bool = false
        private var runOk:Bool = true
        private var readStatus:Int = 1
        
        private var proxySock: Socket
        private var adapter: Adapter?
        private var CCB:CloseCallBack?
        
        
        init(psock:Socket, callBack:@escaping CloseCallBack) {
                
                proxySock = psock
                self.CCB = callBack
                super.init()
                DispatchQueue.global(qos: .default).async {
                        self.Reading()
                }
                
                DispatchQueue.global(qos: .default).async {
                        self.Writing()
                }
        }
        
        func Close() {
                self.CCB?()
                self.proxySock.close()
                self.adapter?.byePeer()
        }
        
        func Reading(){
                
                var readBuffer = Data(capacity: Pipe.PipeBufSize)
                
                defer {
                        self.runOk = false
                        NSLog("---Pipe[\(self.proxySock.socketfd)]---=>:Pipe[\(self.proxySock.socketfd)] exit......")
                }
                
                self.readStatus = 1
                
                do{ repeat{
                        
                        readBuffer.count = 0
                        
                        let rno = try self.proxySock.read(into: &readBuffer)
                        if rno == 0 {
                                NSLog("---Pipe[\(self.proxySock.socketfd)]---=>:read empty data")
                                return
                        }
                        
                        switch self.readStatus {
                                
                                case 1:
                                        let header = try HTTPHeader(headerData: readBuffer)
                                        NSLog("---Pipe[\(self.proxySock.socketfd)]---=>:ProxyFirstRequest \(header.toString())......")
                                        try self.OpenAdapter(header: header)
                                        
                                        if self.isConnCmd{
                                               try self.proxySock.write(from: HTTPData.ConnectSuccessResponse)
                                        }else{
                                               try self.adapter?.writeData(data: readBuffer)
                                        }
                                        
                                        self.readStatus = 2
                                break
                                case 2:
                                        try self.adapter?.writeData(data: readBuffer)
                                break
                        default:
                                return
                        }
                        
                }while self.runOk }catch let err{
                        NSLog("---Pipe[\(self.proxySock.socketfd)]---=>:reading err:\(err.localizedDescription)")
                        return
                }
        }
        
        func Writing(){
                
                defer{
                        self.runOk = false
                        NSLog("---Pipe[\(self.proxySock.socketfd)]---=>:Writing exit......")
                }
                
                do{ repeat{
                        
                        guard let data = try self.adapter?.readData()  else{
                                NSLog("---Pipe[\(self.proxySock.socketfd)]---=>:read from adapter failed")
                                return
                        }
                        
                        try self.proxySock.write(from: data)
                        
                }while self.runOk }catch let err{
                        NSLog("---Pipe[\(self.proxySock.socketfd)]---=>:wrting err:\(err.localizedDescription)")
                        return
                }
        }
}


extension Pipe {
        
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
        }
}
