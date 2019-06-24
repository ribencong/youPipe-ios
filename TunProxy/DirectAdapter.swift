//
//  DirectAdapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
//import Socket
import SocketSwift

class DirectAdapter: Adapter{
        var delegate: PipeWriteDelegate
        var ID: Int32?
        private var sock: Socket
        var running:Bool = true
        var readingBuff = [UInt8](repeating: 0, count: Pipe.PipeBufSize)
        
        init?(targetHost: String, targetPort: Int32, delegate:PipeWriteDelegate) {
                 do {
                        self.delegate = delegate
                        sock = try Socket(.inet, type: .stream, protocol: .tcp)
                        let addr = try sock.addresses(for: targetHost, port: Port(targetPort))
                        try sock.connect(address: addr[0])
                } catch let err {
                        NSLog("---DirectAdapter--=>:Open direct[\(targetHost):\(targetPort)] adapter err:\(err.localizedDescription)")
                        return nil
                }
                
                DispatchQueue.global(qos: .default).async {
                        self.reading()
                }
        }
        
        func reading() {
                
                do{while self.running{
                        
                        let no =  try self.sock.read(&readingBuff, size: Pipe.PipeBufSize)
                        NSLog("---DirectAdapter[\(self.ID!)]--=>:reading from server:\(no)")
                        if no == 0{
                                NSLog("---DirectAdapter[\(self.ID!)]--=>:reading exit case no data")
                                self.byePeer()
                                return
                        }
                        let _ = try self.delegate.write(rawData: Array(readingBuff.prefix(no)))
                        }
                        
                }catch let err{
                 NSLog("---DirectAdapter[\(self.ID!)]--=>:reading err:\(err.localizedDescription)")
                }
        }
        
        func writeData(data: [UInt8]) throws{
                NSLog("---DirectAdapter[\(self.ID!)]--=>:writeData:\(data.count)")
                try self.sock.write(data)
        }
        
        func byePeer() {
                NSLog("---DirectAdapter[\(self.ID!)]--=>:byePeer ")
                self.running = false
                self.sock.close()
        }
}
