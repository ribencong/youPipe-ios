//
//  PacketTunnelProvider.swift
//  PacketTunel
//
//  Created by wsli on 2019/5/22.
//  Copyright © 2019 ribencong. All rights reserved.
//

import NetworkExtension
import IosDelegate

class PacketTunnelProvider: NEPacketTunnelProvider, IosDelegateVpnDelegateProtocol {
        
        var bootNodeSavedPath:String = (Bundle.main.resourceURL?.appendingPathComponent("youPipe").absoluteString)!
        func byPass(_ fd: Int32) -> Bool {
                return true
        }
        
        func getBootPath() -> String {
                return self.bootNodeSavedPath
        }
        
        func readBuff() -> Data? {
                var data:Data?
                self.packetFlow.readPacketObjects { datas in
                        data = datas[0].data
                }
                return data
        }
        
        func write(_ p0: Data?, n: UnsafeMutablePointer<Int>?) throws {
                let data = NEPacket.init(data: p0!, protocolFamily: sa_family_t(AF_INET))
                self.packetFlow.writePacketObjects([data])
        }
        

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
//        do {
       
        
       
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
        networkSettings.mtu = 1500
        let ipv4Settings = NEIPv4Settings(addresses: ["10.8.0.2"], subnetMasks: ["255.255.255.255"])
        networkSettings.ipv4Settings = ipv4Settings
        
        
        
        let proxySettings = NEProxySettings()
        
//        proxySettings.autoProxyConfigurationEnabled = true
//        let bundleURL = Bundle.main.resourceURL!
//        let url = bundleURL.appendingPathComponent("YouPipe.js")//YouPipe_debug.js//YouPipe.js
//        proxySettings.proxyAutoConfigurationURL = url
//        NSLog("url for pac file \(url.absoluteString)")
        
        let proxyPort = 51080
        proxySettings.httpEnabled = true
        proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.httpsEnabled = true
        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.excludeSimpleHostnames = true
        proxySettings.matchDomains = [""]

        networkSettings.proxySettings = proxySettings
        
        setTunnelNetworkSettings(networkSettings){
                err in
                guard err == nil else{
                        print("setTunnelNetworkSettings err:", err!)
                        completionHandler(err)
                        return
                }
                
                completionHandler(nil)
                NSLog("Tunnel start success......")
                self.packetFlow.readPackets {
                        packets, pro in
                        NSLog("pro=%d, data:=%d d=%s", pro, packets.count, String(data: packets[0], encoding: .utf8) ?? "--->>>sss")
                }
        }
//                }catch let err{
//                        NSLog(err.localizedDescription)
//        }
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
