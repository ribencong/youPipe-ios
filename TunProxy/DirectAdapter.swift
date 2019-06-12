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
        
        private var sock: Socket
        
        init?(targetHost: String, targetPort: Int32) {
                 do {
                        sock = try Socket.create()
                        try sock.connect(to: targetHost, port: targetPort, timeout: Pipe.PipeDefaultTimeOut)
                } catch let err {
                        NSLog("---DirectAdapter--=>:Open direct adapter err:\(err.localizedDescription)")
                        return nil
                }
        }
        
        func readData() throws -> Data {
                var buf = Data(capacity: Pipe.PipeBufSize)
                let _ =  try self.sock.read(into: &buf)
                return buf
        }
        
        func write(data: Data) throws{
                try self.sock.write(from: data)
        }
        
        func byePeer() {
                self.sock.close()
        }
}
