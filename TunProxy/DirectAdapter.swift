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
        var ID: Int32?
        private var sock: Socket
        var running:Bool = true
        
        init?(targetHost: String, targetPort: Int32) {
                 do {
                        sock = try Socket.create(family: .inet, type: .stream, proto: .tcp)
                        try sock.connect(to: targetHost, port: targetPort)
                } catch let err {
                        NSLog("---DirectAdapter--=>:Open direct[\(targetHost):\(targetPort)] adapter err:\(err.localizedDescription)")
                        return nil
                }
                
                
        }
        
        func readData(into data: inout Data) throws -> Int{
                
                return try self.sock.read(into: &data)
//                var readingBuff = Data(capacity: Pipe.PipeBufSize)
//                do{while self.running{
//                        readingBuff.count = 0
//                        let no =
//                        NSLog("---DirectAdapter[\(self.ID!)]--=>:reading from server:\(no)")
//                        if no == 0{
//                                NSLog("---DirectAdapter[\(self.ID!)]--=>:reading exit case no data")
//                                return
//                        }
//
//                        readingBuff.prefix(no)
//                        }
//
//                }catch let err{
//                        NSLog("---DirectAdapter[\(self.ID!)]--=>:reading err:\(err.localizedDescription)")
//
//                }
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
