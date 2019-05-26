//
//  PacketTunnelProvider.swift
//  PacketTunel
//
//  Created by wsli on 2019/5/22.
//  Copyright © 2019 ribencong. All rights reserved.
//

import NetworkExtension
import IosDelegate
let proxyPort = 51080

class PacketTunnelProvider: NEPacketTunnelProvider {
        var httpProxy: HTTPProxyServer?
        
        var bootNodeSavedPath:String = (Bundle.main.resourceURL?.appendingPathComponent("youPipe").absoluteString)!

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
        self.httpProxy = HTTPProxyServer()
        self.httpProxy!.start(with: "127.0.0.1", port: proxyPort)
 
        let networkSettings = createSetting()
        
        setTunnelNetworkSettings(networkSettings){
                err in
                guard err == nil else{
                        NSLog("---=>:SetTunnelNetworkSettings err:%s", err.debugDescription)
                        completionHandler(err)
                        return
                }
                
                completionHandler(nil)
                NSLog("---=>:Tunnel start success......")
                self.handlePackets()
        }
    }
        
        func handlePackets() {
                self.packetFlow.readPackets {
                        packets, pro in
                        
                        for (_, pd) in packets.enumerated(){
                                NSLog(IosDelegateParseNsData(pd))
//                                switch pro[idx].int32Value{
//                                        case AF_INET:
//                                        NSLog("---=>:This is IPV4 packet")
//                                        case AF_INET6:
//                                        NSLog("---=>:This is IPV6 packet")
//                                default:
//                                        fatalError()
//                                }
                        }
                        
                        self.handlePackets()
                 }
        }
        
        
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        print("Packet tunnel stopTunnel......")
        completionHandler()
        exit(EXIT_SUCCESS)
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        guard let messageString = NSString(data: messageData, encoding: String.Encoding.utf8.rawValue) else {
                completionHandler?(nil)
                return
        }
        
        NSLog("Got a message from the app: \(messageString)")
        
        let responseData = "Hello app".data(using: String.Encoding.utf8)
        completionHandler?(responseData)
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        
        NSLog("Packet tunnel sleep......")
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
         NSLog("Packet tunnel wake......")
    }
        
        
}

func createSetting()->NEPacketTunnelNetworkSettings?{
        
        //                let ipUrl = bundleURL.appendingPathComponent("bypass.txt")
        //        let ips = try String(contentsOf: ipUrl)
        //
        //                NSLog(ips)
        // var error: NSError?
        //        IosDelegateInitVPN("YPFZStv4N68XpQyjqph4kMVagZDyT9RaUoSAGwzMpFJAKd",
        //                           "2sUfGDAmC6D5Yj1uHVqKTFGYje6NtZfxwN4vfZ4d4xa7vyAHP7NQTNwaRmKnA8s64M2zNPqVwSfCLUW5NkyuQFVCg4F4jAEc2ioSaBjyh9sjV6",
        //                           "{\"sig\":\"+FAKEnV7GOyKp16D4hz4+l91gRnuyAg84z4E9DP+n+kWIy9AcLBYamgkTeGBBaNILvHY7Y0JdvdK9qlkpoMdAw==\",\"start\":\"2019-05-17 09:47:43\",\"end\":\"2019-05-27 09:47:43\",\"user\":\"YPFZStv4N68XpQyjqph4kMVagZDyT9RaUoSAGwzMpFJAKd\"}\n" ,
        //                "",
        //                "",
        //                ips,
        //                self,
        //               &error)
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        networkSettings.mtu = NSNumber(value: UINT16_MAX)
        let ipv4Settings = NEIPv4Settings(addresses: ["10.8.0.2"], subnetMasks: ["255.255.255.255"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        ipv4Settings.excludedRoutes = [
                NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0")
        ]
        networkSettings.ipv4Settings = ipv4Settings
        
        let proxySettings = NEProxySettings()
        proxySettings.excludeSimpleHostnames = true
        proxySettings.matchDomains = [""]
        
//        proxySettings.autoProxyConfigurationEnabled = true
//        let bundleURL = Bundle.main.resourceURL!
//        let url = bundleURL.appendingPathComponent("YouPipe.js")//YouPipe_debug.js//YouPipe.js
//        proxySettings.proxyAutoConfigurationURL = url
//        NSLog("url for pac file \(url.absoluteString)")

        
        proxySettings.autoProxyConfigurationEnabled = false
        proxySettings.excludeSimpleHostnames = true
        proxySettings.httpEnabled = true
        proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.httpsEnabled = true
        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.exceptionList = [
                "192.168.0.0/16",
                "10.0.0.0/8",
                "172.16.0.0/12",
                "127.0.0.1",
                "localhost",
                "*.local"
        ]
        networkSettings.proxySettings = proxySettings
        
//        let dnsSettings = NEDNSSettings(servers: [])
//        // This overrides system DNS settings
//        dnsSettings.matchDomains = [""]
//        networkSettings.dnsSettings = dnsSettings
        
        return networkSettings
}
