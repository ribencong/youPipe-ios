//
//  PacketTunnelProvider.swift
//  Tun2Pipe
//
//  Created by wsli on 2019/5/30.
//  Copyright © 2019 ribencong. All rights reserved.
//

import NetworkExtension

let proxyPort = 51080
class PacketTunnelProvider: NEPacketTunnelProvider {

        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
             
                let networkSettings = newPacketTunnelSettings(proxyHost: "127.0.0.1", proxyPort: UInt16(proxyPort))
                
                setTunnelNetworkSettings(networkSettings){
                        err in
                        guard err == nil else{
                                NSLog("---=>:SetTunnelNetworkSettings err:%s", err.debugDescription)
                                completionHandler(err)
                                return
                        }
                        
                        completionHandler(nil)
                        
                        self.handlePackets()
                        
                        NSLog("---=>:Tunnel start success......")
                }
        }
        
        override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
                NSLog("Packet tunnel stopTunnel......")
                completionHandler()
                exit(EXIT_SUCCESS)
        }
        
        func handlePackets() {
                
                self.packetFlow.readPackets {
                        packets, pro in
                        
                        for (_, pd) in packets.enumerated(){
                                NSLog("pakcet:\(pd.count)")
                        }
                        
                        self.handlePackets()
                }
        }
}


func newPacketTunnelSettings(proxyHost: String, proxyPort: UInt16) -> NEPacketTunnelNetworkSettings {
        
        
        let settings: NEPacketTunnelNetworkSettings = NEPacketTunnelNetworkSettings(
                tunnelRemoteAddress: "240.0.0.1"
        )
        /* MTU */
        settings.mtu = NSNumber(value: UINT16_MAX)
        
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
        proxySettings.matchDomains = ["baidu.com"]
        settings.proxySettings = proxySettings
        
        /* ipv4 settings */
        let ipv4Settings: NEIPv4Settings = NEIPv4Settings(
                addresses: ["10.8.0.2"],
                subnetMasks: ["255.255.255.255"]
        )
//        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        ipv4Settings.excludedRoutes = [
                NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0")
        ]
        settings.ipv4Settings = ipv4Settings
        
        return settings
}
