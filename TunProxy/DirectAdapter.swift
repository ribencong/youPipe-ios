//
//  DirectAdapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class DirectAdapter: Adapter{
        
        private var sock: GCDAsyncSocket
        
        init?(targetHost: String, targetPort: UInt16, delegae:GCDAsyncSocketDelegate) {
                
                sock = GCDAsyncSocket(delegate: delegae, delegateQueue:
                        HttpProxy.queue, socketQueue: HttpProxy.queue)
                
                do {
                        try sock.connect(toHost: targetHost,
                                         onPort: targetPort)
                } catch let err {
                        NSLog("Open direct adapter err:\(err.localizedDescription)")
                        return nil
                }
        }
        
        func readData(tag: Int) {
                self.sock.readData(withTimeout: -1, tag: tag)
        }
        
        func write(data: Data, tag: Int) {
                self.sock.write(data, withTimeout: -1, tag: tag)
        }
        
        func byePeer() {
                self.sock.disconnectAfterReadingAndWriting()
        }
}
