//
//  FreePipe.swift
//  PacketTunel
//
//  Created by wsli on 2019/5/28.
//  Copyright © 2019 ribencong. All rights reserved.
//

import Foundation
import CocoaAsyncSocket


struct Action {
        static let ReqHead:Int = 1
}


class Pipe: NSObject{
        var inSock:GCDAsyncSocket
        let queue: DispatchQueue = DispatchQueue(label: "HTTPConnection.delegateQueue")
        var finishCall : ((Pipe)->Void)? = nil
        
        init(inSock : GCDAsyncSocket, completeHandler:@escaping (Pipe) -> Void){
                self.inSock = inSock
                self.finishCall = completeHandler
                super.init()
                
                self.inSock.synchronouslySetDelegate(
                        self,
                        delegateQueue: queue
                )
                self.inSock.readData(withTimeout: 5, tag: Action.ReqHead)
        }
}

extension Pipe: GCDAsyncSocketDelegate{
        func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int){
                guard let msg: String = String.init(data: data, encoding: .ascii) else {
                        NSLog("data convert to string err:\(data)")
                        return
                }
                let header  = SimpleHttpHeader(headStr: msg)
                NSLog("m:\(header.method!.rawValue) u:\(header.url!) h:\(header.host!) p:\(header.port)")
        }
}
