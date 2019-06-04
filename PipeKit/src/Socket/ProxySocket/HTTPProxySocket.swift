import Foundation

public class HTTPProxySocket: ProxySocket {
        var UUID:Int?=0
    enum HTTPProxyReadStatus: CustomStringConvertible {
        case invalid,
        readingFirstHeader,
        pendingFirstHeader,
        readingHeader,
        readingContent,
        stopped
        
        var description: String {
            switch self {
            case .invalid:
                return "invalid"
            case .readingFirstHeader:
                return "reading first header"
            case .pendingFirstHeader:
                return "waiting to send first header"
            case .readingHeader:
                return "reading header (forwarding)"
            case .readingContent:
                return "reading content (forwarding)"
            case .stopped:
                return "stopped"
            }
        }
    }
    
    enum HTTPProxyWriteStatus: CustomStringConvertible {
        case invalid,
        sendingConnectResponse,
        forwarding,
        stopped
        
        var description: String {
            switch self {
            case .invalid:
                return "invalid"
            case .sendingConnectResponse:
                return "sending response header for CONNECT"
            case .forwarding:
                return "waiting to begin forwarding data"
            case .stopped:
                return "stopped"
            }
        }
    }
    /// The remote host to connect to.
    public var destinationHost: String!
    
    /// The remote port to connect to.
    public var destinationPort: Int!
    
    private var currentHeader: HTTPHeader!
    
    private let scanner: HTTPStreamScanner = HTTPStreamScanner()
    
    private var readStatus: HTTPProxyReadStatus = .invalid
    private var writeStatus: HTTPProxyWriteStatus = .invalid
    
    public var isConnectCommand = false
    
    public var readStatusDescription: String {
        return readStatus.description
    }
    
    public var writeStatusDescription: String {
        return writeStatus.description
    }
    
    /**
     Begin reading and processing data from the socket.
     */
    override public func openSocket() {
        super.openSocket()
        
        guard !isCancelled else {
            return
        }
        
        readStatus = .readingFirstHeader
        socket.readDataTo(data: Utils.HTTPData.DoubleCRLF)
        
        NSLog("-[\(self.UUID!)]--(30)--->http proxy openSocket .....")
    }
    
    override public func readData() {
        guard !isCancelled else {
            return
        }
        
        // Return the first header we read when the socket was opened if the proxy command is not CONNECT.
        if readStatus == .pendingFirstHeader {
                NSLog("-[\(self.UUID!)]--(3)--->http first head pending so read it .....")
            delegate?.didRead(data: currentHeader.toData(), from: self)
            readStatus = .readingContent
            return
        }
        
        switch scanner.nextAction {
        case .readContent(let length):
                
                NSLog("-[\(self.UUID!)]--(14)--->http go on reading content \(length) .....")
            readStatus = .readingContent
            if length > 0 {
                socket.readDataTo(length: length)
            } else {
                socket.readData()
            }
        case .readHeader:
                NSLog("-[\(self.UUID!)]--(15)--->http read header again  .....")
            readStatus = .readingHeader
            socket.readDataTo(data: Utils.HTTPData.DoubleCRLF)
        case .stop:
                NSLog("-[\(self.UUID!)]--(16)--->http read stopping .....")
            readStatus = .stopped
            disconnect()
        }
        
    }
    
    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    /**
     The socket did read some data.
     
     - parameter data:    The data read from the socket.
     - parameter from:    The socket where the data is read from.
     */
    override public func didRead(data: Data, from: RawTCPSocketProtocol) {
        super.didRead(data: data, from: from)
        
        if let readStr = String(data: data, encoding: .ascii) {
                NSLog("------>Http proxy read:\n \(readStr)")
        }
        
        let result: HTTPStreamScanner.Result
        do {
            result = try scanner.input(data)
        } catch let error {
            disconnect(becauseOf: error)
            return
        }
        
        switch (readStatus, result) {
        case (.readingFirstHeader, .header(let header)):
            currentHeader = header
            currentHeader.removeProxyHeader()
            currentHeader.rewriteToRelativePath()
            
            destinationHost = currentHeader.host
            destinationPort = currentHeader.port
            isConnectCommand = currentHeader.isConnect
            
            if !isConnectCommand {
                readStatus = .pendingFirstHeader
            } else {
                readStatus = .readingContent
            }
            NSLog("-[\(self.UUID!)]--(12)--->http proxy get first  head[\(header.toString())] .....")
            session = ConnectSession(host: destinationHost!, port: destinationPort!)
            observer?.signal(.receivedRequest(session!, on: self))
            delegate?.didReceive(session: session!, from: self)
        case (.readingHeader, .header(let header)):
            currentHeader = header
            currentHeader.removeProxyHeader()
            currentHeader.rewriteToRelativePath()
            
            NSLog("-[\(self.UUID!)]--(17)--->http proxy get header again [\(header.toString())] .....")
            delegate?.didRead(data: currentHeader.toData(), from: self)
        case (.readingContent, .content(let content)):
                NSLog("-[\(self.UUID!)]--(18)--->http proxy get content [\(content.count)] .....")
            delegate?.didRead(data: content, from: self)
        default:
                NSLog("-[\(self.UUID!)]--(40)--->Http proxy didRead unknown case")
            return
        }
    }
    
    /**
     The socket did send some data.
     
     - parameter data:    The data which have been sent to remote (acknowledged). Note this may not be available since the data may be released to save memory.
     - parameter by:    The socket where the data is sent out.
     */
    override public func didWrite(data: Data?, by: RawTCPSocketProtocol) {
        super.didWrite(data: data, by: by)
        
        switch writeStatus {
        case .sendingConnectResponse:
            writeStatus = .forwarding
            observer?.signal(.readyForForward(self))
            
            NSLog("-[\(self.UUID!)]--(19)--->http proxy write back connect response .....")
            delegate?.didBecomeReadyToForwardWith(socket: self)
        default:
                NSLog("-[\(self.UUID!)]--(22)--->http proxy write back for Get responses \(data?.count ?? 0) .....")
            delegate?.didWrite(data: data, by: self)
        }
    }
    
    /**
     Response to the `AdapterSocket` on the other side of the `Tunnel` which has succefully connected to the remote server.
     
     - parameter adapter: The `AdapterSocket`.
     */
    public override func respondTo(adapter: AdapterSocket) {
        super.respondTo(adapter: adapter)
        
        guard !isCancelled else {
            return
        }
        
        if isConnectCommand {
            writeStatus = .sendingConnectResponse
            write(data: Utils.HTTPData.ConnectSuccessResponse)
                NSLog("-[\(self.UUID!)]--(21)--->http proxy response to Connect action .....")
        } else {
            writeStatus = .forwarding
            observer?.signal(.readyForForward(self))
                NSLog("-[\(self.UUID!)]--(20)--->http proxy response to Get action .....")
            delegate?.didBecomeReadyToForwardWith(socket: self)
        }
    }
}
