//
//  PacketTunnelProvider.swift
//  PacketTunel
//
//  Created by wsli on 2019/5/22.
//  Copyright © 2019 ribencong. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
        
         var pacServer:PacServer = PacServer()

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("start Tunnel:\(String(describing: options))")
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        networkSettings.mtu = 1500
        let ipv4Settings = NEIPv4Settings(addresses: ["10.8.0.2"], subnetMasks: ["255.255.255.255"])
        networkSettings.ipv4Settings = ipv4Settings
        
        let proxySettings = NEProxySettings()
        proxySettings.autoProxyConfigurationEnabled = true
        let bundleURL = Bundle.main.resourceURL!
        let url = bundleURL.appendingPathComponent("YouPipe.js")//YouPipe_debug.js//YouPipe.js
        proxySettings.proxyAutoConfigurationURL = url
        
        networkSettings.proxySettings = proxySettings
        
        setTunnelNetworkSettings(networkSettings){
                err in
                guard err == nil else{
                        print("setTunnelNetworkSettings err:", err!)
                        completionHandler(err)
                        return
                }
                
                completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        print("stopTunnel")
        // Add code here to start the process of stopping the tunnel.
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
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
         print("wake")
    }
}
