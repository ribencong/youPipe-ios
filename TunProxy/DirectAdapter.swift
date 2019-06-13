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
        
        init?(targetHost: String, targetPort: Int32, delegate:PipeWriteDelegate) {
                 do {
                        self.delegate = delegate
                        sock = try Socket.create()
                        try sock.connect(to: targetHost, port: targetPort)
                } catch let err {
                        NSLog("---DirectAdapter--=>:Open direct[\(targetHost):\(targetPort)] adapter err:\(err.localizedDescription)")
                        return nil
                }
                
                DispatchQueue.global(qos: .default).async {
                        self.reading()
                }
        }
        
        func reading() {
                
                do{while true{
                        var buf = Data(capacity: Pipe.PipeBufSize)
                        let _ =  try self.sock.read(into: &buf)
                        let _ = try self.delegate.write(rawData: buf)
                        }
                }catch let err{
                 NSLog("---DirectAdapter--=>:reading err:\(err.localizedDescription)")
                }
        }
        
        func writeData(data: Data) throws{
//                NSLog("---DirectAdapter--=>:writeData:\(data.count)")
                try self.sock.write(from: data)
        }
        
        func byePeer() {
                NSLog("---DirectAdapter[\(self.ID!)]--=>:byePeer ")
                self.sock.close()
        }
}
