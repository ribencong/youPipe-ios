//
//  PacketTunnelProvider.swift
//  TunProxy
//
//  Created by wsli on 2019/6/1.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
        
        
        
        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
                HttpProxy.shared.start(with: "127.0.0.1", port: 51080)
                
                let networkSettings = newPacketTunnelSettings(proxyHost: "127.0.0.1", proxyPort: 51080)
                
                TCPProxyServer.share.server.ipv4Setting(
                        withAddress: (networkSettings.ipv4Settings?.addresses[0])!,
                        netmask: (networkSettings.ipv4Settings?.subnetMasks[0])!)
                
                TCPProxyServer.share.server.mtu(networkSettings.mtu!.uint16Value) {
                        (ds  ,ns) in
                        guard let data = ds, let nums = ns else{
                                return
                        }
                        
                        self.packetFlow.writePackets(data, withProtocols: nums)
                }
                
                setTunnelNetworkSettings(networkSettings) {
                        error in
                        
                        completionHandler(error)
                        
                        guard error == nil else {
                                return
                        }
                        
                        self.packetFlow.readPackets() { datas, nums in
                                self.handlePackets(packets: datas, protocols: nums)
                        }
                }
        }
        
        func handlePackets(packets: [Data], protocols: [NSNumber]) {
                for (index, data) in packets.enumerated() {
                        switch protocols[index].int32Value {
                        case AF_INET:
                                TCPProxyServer.share.server.ipPacketInput(data)
                        case AF_INET6:
                                break
                        default:
                                fatalError()
                        }
                }
                self.packetFlow.readPackets { datas, numbers in
                        self.handlePackets(packets: datas, protocols: numbers)
                }
        }
    
        override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
                completionHandler()
                exit(EXIT_SUCCESS)
        }
        
        
        func newPacketTunnelSettings(proxyHost: String, proxyPort: UInt16) -> NEPacketTunnelNetworkSettings {
                let settings: NEPacketTunnelNetworkSettings = NEPacketTunnelNetworkSettings(
                        tunnelRemoteAddress: "10.8.0.2"
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
                settings.proxySettings = proxySettings
                
                /* ipv4 settings */
                let ipv4Settings: NEIPv4Settings = NEIPv4Settings(
                        addresses: [settings.tunnelRemoteAddress],
                        subnetMasks: ["255.255.255.255"]
                )
                ipv4Settings.includedRoutes = [NEIPv4Route.default()]
                ipv4Settings.excludedRoutes = [
                        NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
                        NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                        NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0")
                ]
                settings.ipv4Settings = ipv4Settings
                
                /* MTU */
                settings.mtu = NSNumber(value: UINT16_MAX)
                
                return settings
        }
}
