//
//  PacketTunnelProvider.swift
//  PacketTunel
//
//  Created by wsli on 2019/5/22.
//  Copyright © 2019 ribencong. All rights reserved.
//

import NetworkExtension
import IosLib
let proxyPort = 51080
let domainsURL = "https://raw.githubusercontent.com/youpipe/ypctorrent/master/gfw.torrent"

class PacketTunnelProvider: NEPacketTunnelProvider {
        var httpProxy: HTTPProxyServer?
        
        var bootNodeSavedPath:String = (Bundle.main.resourceURL?.appendingPathComponent("youPipe").absoluteString)!

        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {

                self.httpProxy = HTTPProxyServer()
                self.httpProxy!.start(with: "127.0.0.1", port: proxyPort)

                let networkSettings = newPacketTunnelSettings(proxyHost: "127.0.0.1", proxyPort: UInt16(proxyPort))

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
                        
//                        for (_, pd) in packets.enumerated(){
//                                IosLibInputPacket(pd)
//                        }
                        
                        self.handlePackets()
                 }
        }
        
        
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        print("Packet tunnel stopTunnel......")
        completionHandler()
        exit(EXIT_SUCCESS)
    }
        
}

func newPacketTunnelSettings(proxyHost: String, proxyPort: UInt16) -> NEPacketTunnelNetworkSettings {
        let settings: NEPacketTunnelNetworkSettings = NEPacketTunnelNetworkSettings(
                tunnelRemoteAddress: "240.0.0.1"
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
        proxySettings.matchDomains = ["facebook.com", "sina.com.cn"]
        settings.proxySettings = proxySettings
        
        /* ipv4 settings */
        let ipv4Settings: NEIPv4Settings = NEIPv4Settings(
                addresses: ["10.8.0.2"],
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

extension PacketTunnelProvider: IosLibVpnDelegateProtocol{
        func byPass(_ fd: Int32) -> Bool {
                return true
        }
        
        func log(_ str: String?) {
                NSLog("---=>:\(str ?? "空数据")")
        }
        
        func write(_ p0: Data?, n: UnsafeMutablePointer<Int>?) throws {

                guard let data = p0 else{
                        return
                }

                let pk = NEPacket(data: data, protocolFamily: sa_family_t(AF_INET))
                self.packetFlow.writePacketObjects([pk])
        }
}
