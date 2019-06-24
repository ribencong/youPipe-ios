//
//  Tunnel.swift
//  TunProxy
//
//  Created by wsli on 2019/6/3.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
//import Socket
import SocketSwift

typealias CloseCallBack = ()->Void

public struct HTTPData {
        public static let DoubleCRLF = "\r\n\r\n".data(using: String.Encoding.utf8)!
        public static let CRLF = "\r\n".data(using: String.Encoding.utf8)!
        public static let ConnectSuccessResponse = [UInt8]("HTTP/1.1 200 Connection Established\r\n\r\n".utf8)
}

class Pipe: NSObject{
        
        static let  PipeBufSize:Int         = 1 << 14
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
        }
        
        func Close() {
                self.CCB?()
                self.proxySock.close()
                self.adapter?.byePeer()
        }
        
        func Reading(){
                
                var readBuffer = [UInt8](repeating: 0, count: Pipe.PipeBufSize)
                
                defer {
                        self.runOk = false
                        NSLog("---Pipe[\(self.proxySock.fileDescriptor)]---=>reading exit......")
                        self.Close()
                }
                
                self.readStatus = 1
                
                do{ repeat{
                        let rno = try self.proxySock.read(&readBuffer, size: Pipe.PipeBufSize)
                        if rno == 0 {
                                NSLog("---Pipe[\(self.proxySock.fileDescriptor)]---=>:read empty data")
                                return
                        }
                        
                        switch self.readStatus {
                        case 1:
                                let header = try HTTPHeader(headerData: readBuffer)
                                NSLog("---Pipe[\(self.proxySock.fileDescriptor)]---=>:ProxyFirstRequest \(header.toString())......")
                                
                                try self.OpenAdapter(header: header)
                                
                                if self.isConnCmd{
                                       try self.proxySock.write(HTTPData.ConnectSuccessResponse)
                                }else{
                                       try self.adapter?.writeData(data: Array(readBuffer.prefix(rno)))
                                }
                                
                                self.readStatus = 2
                        break
                        case 2:
                                try self.adapter?.writeData(data: Array(readBuffer.prefix(rno)))
                        break
                        default:
                                NSLog("---Pipe[\(self.proxySock.fileDescriptor)]---=>:unknown reading status:\(self.readStatus)")
                                return
                        }
                        
                }while self.runOk }catch let err{
                        NSLog("---Pipe[\(self.proxySock.fileDescriptor)]---=>:reading err:\(err.localizedDescription)")
                        return
                }
        }
        
        func OpenAdapter(header:HTTPHeader) throws {

                self.targetAddr = header.host
                self.targetoPort = Int32(header.port)
                self.isConnCmd = header.isConnect
                
                if Domains.shared.Hit(host: header.host){
                        self.adapter = PipeAdapter(targetHost: self.targetAddr!,
                                                   targetPort: self.targetoPort!,
                                                   delegate: self)
                }else{
                        self.adapter = DirectAdapter(targetHost: self.targetAddr!,
                                                     targetPort: self.targetoPort!,
                                                     delegate:self)
                }
                self.adapter?.ID = self.proxySock.fileDescriptor
                NSLog("---Pipe[\(self.proxySock.fileDescriptor)]---=>:first header:\(header.toString())")
        }
}

extension Pipe: PipeWriteDelegate{
        
        func write(rawData: [UInt8]) throws -> Int {
                try self.proxySock.write(rawData)
                NSLog("---Pipe[\(self.proxySock.fileDescriptor)]---=>:PipeWriteDelegate writing data len:\(rawData.count)")
                return rawData.count
        }
}
