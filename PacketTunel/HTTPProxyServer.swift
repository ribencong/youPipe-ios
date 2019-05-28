import Foundation
import CocoaAsyncSocket

class HTTPProxyServer: NSObject {
    
        let listenSocket: GCDAsyncSocket
        fileprivate var proxyReq: Set<Pipe> = []
        
        override init() {
        self.listenSocket = GCDAsyncSocket()
        super.init()
        self.listenSocket.synchronouslySetDelegate(
            self,
            delegateQueue: DispatchQueue(label: "HTTPProxyServer.delegateQueue")
        )
    }
    
    func start(with host: String, port:Int) {
        do {
                try self.listenSocket.accept(onInterface: host, port: UInt16(port))
        } catch {
            assertionFailure("\(error)")
        }
    }
}

extension HTTPProxyServer: GCDAsyncSocketDelegate {
        func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
                NSLog("---=>:Accept:\(newSocket.connectedHost!):\(newSocket.connectedPort)->\(newSocket.localHost!):\(newSocket.localPort)")
                
                let p = Pipe(inSock: newSocket){
                        pp in
                        self.proxyReq.remove(pp)
                }
                
                self.proxyReq.insert(p)
        }
}
