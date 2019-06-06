//
//  PacketTunnelProvider.swift
//  TunProxy
//
//  Created by wsli on 2019/6/1.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import NetworkExtension

let ProxyPort = 51080

class PacketTunnelProvider: NEPacketTunnelProvider {
        var started:Bool = false  
        var httpProxy:HttpProxy!
        
        
        func startByYouPipe(completionHandler: @escaping (Error?) -> Void){
                
                let networkSettings = newPacketTunnelSettings(proxyHost: "127.0.0.1", proxyPort: UInt16(ProxyPort))
                setTunnelNetworkSettings(networkSettings) {
                        error in
                        
                        completionHandler(error)
                        
                        guard error == nil else {
                                return
                        }
                        
                        self.httpProxy = HttpProxy(host: "127.0.0.1", port: UInt16(ProxyPort))
                }
        }
        
        
        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
                guard let opts = options else{
                        completionHandler(YPError.VPNParamLost)
                        NSLog(YPError.VPNParamLost.localizedDescription)
                        return
                }
                
                for (key, val) in opts{
                        NSLog("------>k[\(key)]=v[\(val)]")
                }
                
                do {
                        try  PipeWallet.shared.Establish(conf: opts)
                }catch let err{
                        completionHandler(err)
                        NSLog("establish connection to miner err:\(err.localizedDescription)")
                        return
                }
               
                startByYouPipe(completionHandler: completionHandler)
        }
    
        override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
                completionHandler()
                exit(EXIT_SUCCESS)
        }
        
        
        func newPacketTunnelSettings(proxyHost: String, proxyPort: UInt16) -> NEPacketTunnelNetworkSettings {
                let settings: NEPacketTunnelNetworkSettings = NEPacketTunnelNetworkSettings(
                        tunnelRemoteAddress: "8.8.8.8"
                )
                
                /* proxy settings */
                let proxySettings: NEProxySettings = NEProxySettings()
                proxySettings.httpServer = NEProxyServer(
                        address: proxyHost,
                        port: Int(proxyPort)
                )
                proxySettings.httpsServer = NEProxyServer(
                        address: proxyHost,
                        port: Int(proxyPort)
                )
                proxySettings.autoProxyConfigurationEnabled = false
                proxySettings.httpEnabled = true
                proxySettings.httpsEnabled = true
                proxySettings.excludeSimpleHostnames = true
                proxySettings.exceptionList = [
                        "192.168.0.0/16",
                        "10.0.0.0/8",
                        "172.16.0.0/12",
                        "127.0.0.1",
                        "localhost",
                        "*.local"
                ]
                proxySettings.matchDomains=[""]
                proxySettings.exceptionList = ["api.smoot.apple.com","configuration.apple.com","xp.apple.com","smp-device-content.apple.com","guzzoni.apple.com","captive.apple.com","*.ess.apple.com","*.push.apple.com","*.push-apple.com.akadns.net"]
                settings.proxySettings = proxySettings
                
                /* ipv4 settings */
                let ipv4Settings: NEIPv4Settings = NEIPv4Settings(
                        addresses: ["10.8.0.2"],
                        subnetMasks: ["255.255.255.0"]
                )
                
//                ipv4Settings.includedRoutes = [NEIPv4Route.default()]
//                ipv4Settings.excludedRoutes = [
//                        NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
//                        NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
//                        NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
//                        NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
//                        NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
//                        NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
//                        NEIPv4Route(destinationAddress: "17.0.0.0", subnetMask: "255.0.0.0"),
//                ]
                
                settings.ipv4Settings = ipv4Settings
                
                /* MTU */
                settings.mtu = NSNumber(value: UINT16_MAX)
                
                return settings
        }
} 
