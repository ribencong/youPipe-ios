//
//  DirectAdapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import Socket

class DirectAdapter: Adapter{
        var delegate: PipeWriteDelegate
        var ID: Int32?
        private var sock: Socket
        var running:Bool = true
        let queue = DispatchQueue.global(qos: .default)
        
        init?(targetHost: String, targetPort: Int32, delegate:PipeWriteDelegate) {
                 do {
                        self.delegate = delegate
                        sock = try Socket.create(family: .inet, type: .stream, proto: .tcp)
                        try sock.connect(to: targetHost, port: targetPort)
                } catch let err {
                        NSLog("---DirectAdapter--=>:Open direct[\(targetHost):\(targetPort)] adapter err:\(err.localizedDescription)")
                        return nil
                }
                
                self.queue.async {
                        [unowned self] in
                        self.reading()
                }
        }
        
        func reading() {
                
                defer{
                        self.delegate.breakPipe()
                }
                
                var readingBuff = Data(capacity: Pipe.PipeBufSize)
                do{while self.running{
                        
                        let no =  try self.sock.read(into: &readingBuff)
                        NSLog("---DirectAdapter[\(self.ID!)]--=>:reading from server:\(no)")
                        if no == 0{
                                NSLog("---DirectAdapter[\(self.ID!)]--=>:reading exit case no data")
                                return
                        }
                        let _ = try self.delegate.write(rawData: readingBuff.prefix(no))
                        
                        readingBuff.count = 0
                        }
                        
                }catch let err{
                        NSLog("---DirectAdapter[\(self.ID!)]--=>:reading err:\(err.localizedDescription)")
                        
                }
        }
        
        func writeData(data: Data) throws{
                NSLog("---DirectAdapter[\(self.ID!)]--=>:writeData:\(data.count)")
                try self.sock.write(from: data)
        }
        
        func byePeer() {
                NSLog("---DirectAdapter[\(self.ID!)]--=>:byePeer ")
                self.running = false
                self.sock.close()
        }
}
