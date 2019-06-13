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
        
        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
                
                print("-------------------------------")
                
                guard let opts = options else{
                        completionHandler(YPError.VPNParamLost)
                        NSLog(YPError.VPNParamLost.localizedDescription)
                        return
                }
                
                guard let proxy = HttpProxy( host: "127.0.0.1", port:ProxyPort) else{
                        completionHandler(YPError.HttpProxyFailed)
                        return
                }
                
                self.httpProxy = proxy
                self.httpProxy.Run()
                
                let networkSettings = newPacketTunnelSettings(proxyHost: "127.0.0.1", proxyPort: UInt16(ProxyPort))
                
                PipeWallet.shared.Establish(conf: opts){
                        err in
                        guard err == nil else {
                                self.ReleaseResource()
                                completionHandler(err)
                                NSLog("---(Tunnel)---=>:establish connection to miner err:\(err!.localizedDescription)")
                                return
                        }
                        
                        self.setTunnelNetworkSettings(networkSettings) {
                                error in
                                completionHandler(error)
                                guard error == nil else {
                                        self.ReleaseResource()
                                        return
                                }
                        }
                }
        }
        
        func ReleaseResource(){
                self.httpProxy?.Close()
                PipeWallet.shared.Close()
                exit(EXIT_SUCCESS)
        }
    
        override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
                completionHandler()
                exit(EXIT_SUCCESS)
        }
        
        
        func newPacketTunnelSettings(proxyHost: String, proxyPort: UInt16) -> NEPacketTunnelNetworkSettings {
                let settings: NEPacketTunnelNetworkSettings = NEPacketTunnelNetworkSettings(
                        tunnelRemoteAddress: "8.8.8.8"
                )
                
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
                settings.proxySettings = proxySettings
                
                let ipv4Settings: NEIPv4Settings = NEIPv4Settings(
                        addresses: ["10.8.0.2"],
                        subnetMasks: ["255.255.255.0"]
                )

                settings.ipv4Settings = ipv4Settings
                
                /* MTU */
                settings.mtu = NSNumber(value: UINT16_MAX)
                
                return settings
        }
} 
