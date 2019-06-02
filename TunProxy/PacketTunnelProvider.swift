//
//  PacketTunnelProvider.swift
//  TunProxy
//
//  Created by wsli on 2019/6/1.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import NetworkExtension
import NEKit
import SwiftyJSON

let ProxyPort = 51080

class PacketTunnelProvider: NEPacketTunnelProvider {
        var started:Bool = false
        var proxyServer: ProxyServer!
        var lastPath:NWPath?
        
        
        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
                NSLog("开始连接---------------------------------------")
//
                let obfuscater = ShadowsocksAdapter.ProtocolObfuscater.OriginProtocolObfuscater.Factory()
                let algorithm:CryptoAlgorithm = .AES256CFB
//
//                let socks5AF = SOCKS5AdapterFactory(serverHost: "127.0.0.1", serverPort: ProxyPort)
                
                let socks5AF = ShadowsocksAdapterFactory(serverHost: "174.7.124.45",
                                                                 serverPort: 54321,
                                                                 protocolObfuscaterFactory:obfuscater,
                                                                 cryptorFactory: ShadowsocksAdapter.CryptoStreamProcessor.Factory(password: "rickey.liao", algorithm: algorithm),
                                                                 streamObfuscaterFactory: ShadowsocksAdapter.StreamObfuscater.OriginStreamObfuscater.Factory())
//
                let directAdapterFactory = DirectAdapterFactory()
                
                let json_str = getRuleConf()
                let json = JSON.init(parseJSON: json_str)
                
                var UserRules:[NEKit.Rule] = []
                
                let arraydom = json["rules"]["DOMAIN"].arrayValue
                let arrayip = json["rules"]["IP"].arrayValue
                let dom_direct = getDomRule(list: arraydom, isDirect: true)
                UserRules.append(DomainListRule(adapterFactory: directAdapterFactory, criteria: dom_direct))
                
                let ip_direct = getIPRule(list: arrayip, isDirect: true)
                var ipdirect:NEKit.Rule!
                do {
                        ipdirect = try IPRangeListRule(adapterFactory: directAdapterFactory, ranges: ip_direct)
                }catch let error as NSError {
                        NSLog("ip解析:"+error.domain)
                }
                UserRules.append(ipdirect)
                
                let dom_proxy = getDomRule(list: arraydom, isDirect: false)
                UserRules.append(DomainListRule(adapterFactory: socks5AF, criteria: dom_proxy))
                let ip_proxy = getIPRule(list: arrayip, isDirect: false)
                
                var iprule:NEKit.Rule!
                do {
                        iprule = try IPRangeListRule(adapterFactory: socks5AF, ranges: ip_proxy)
                }catch let error as NSError {
                        NSLog("ip解析:"+error.domain)
                }
                UserRules.append(iprule)
                
                
                // Rules
                let chinaRule = CountryRule(countryCode: "CN", match: true, adapterFactory: directAdapterFactory)
                let unKnowLoc = CountryRule(countryCode: "--", match: true, adapterFactory: directAdapterFactory)
                let dnsFailRule = DNSFailRule(adapterFactory: socks5AF)
                
                let allRule = AllRule(adapterFactory: socks5AF)
                UserRules.append(contentsOf: [chinaRule,unKnowLoc,dnsFailRule,allRule])
                
                let manager = RuleManager(fromRules: UserRules, appendDirect: true)
                RuleManager.currentManager = manager
                
                let networkSettings = newPacketTunnelSettings(proxyHost: "127.0.0.1", proxyPort: UInt16(ProxyPort))
                setTunnelNetworkSettings(networkSettings) {
                        error in
                        
                        completionHandler(error)
                        
                        guard error == nil else {
                                return
                        }
                        
                        if !self.started{
                                self.proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: "127.0.0.1"), port: NEKit.Port(port: UInt16(ProxyPort)))
//                                self.proxyServer = GCDSOCKS5ProxyServer(address: IPAddress(fromString: "127.0.0.1"),
//                                                                        port: NEKit.Port(port: UInt16(ProxyPort)))
                                try! self.proxyServer.start()
//                                self.addObserver(self, forKeyPath: "defaultPath", options: .initial, context: nil)
                                
                                self.started = true
                        }else{
                                self.proxyServer.stop()
                                try! self.proxyServer.start()
                        }
                }
        }
    
        override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
                
                if(proxyServer != nil){
                        proxyServer.stop()
                        proxyServer = nil
                        RawSocketFactory.TunnelProvider = nil
                }
                
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

extension PacketTunnelProvider{
        fileprivate func getRuleConf() -> String{
                let Path = Bundle.main.path(forResource: "rules", ofType: "json")
                let Data = try? Foundation.Data(contentsOf: URL(fileURLWithPath: Path!))
                let str = String(data: Data!, encoding: String.Encoding.utf8)!
                return str
        }
        
        func getDomRule(list:[JSON],isDirect:Bool) -> [NEKit.DomainListRule.MatchCriterion] {
                var rule_dom : [NEKit.DomainListRule.MatchCriterion] = []
                for item in list {
                        let str = item.stringValue.replacingOccurrences(of: " ", with: "")
                        let components = str.components(separatedBy: ",")
                        let type = components[0]
                        let value = components[1]
                        let adap = components[2]
                        if isDirect {
                                if type=="DOMAIN-SUFFIX" && adap=="DIRECT" {
                                        rule_dom.append(DomainListRule.MatchCriterion.suffix(value))
                                }
                                if type=="DOMAIN-KEYWORD" && adap=="DIRECT" {
                                        rule_dom.append(DomainListRule.MatchCriterion.suffix(value))
                                }
                        }else{
                                if type=="DOMAIN-SUFFIX" && adap=="PROXY" {
                                        rule_dom.append(DomainListRule.MatchCriterion.suffix(value))
                                }
                                if type=="DOMAIN-KEYWORD" && adap=="PROXY" {
                                        rule_dom.append(DomainListRule.MatchCriterion.suffix(value))
                                }
                        }
                }
                return rule_dom
        }
        
        func getIPRule(list:[JSON],isDirect:Bool) -> [String] {
                var rule_ip : [String] = []
                for item in list {
                        let str = item.stringValue.replacingOccurrences(of: " ", with: "")
                        let components = str.components(separatedBy: ",")
                        //            let type = components[0]
                        let value = components[1]
                        let adap = components[2]
                        if isDirect {
                                if adap=="DIRECT" {
                                        rule_ip.append(value)
                                }
                        }else{
                                if adap=="PROXY" {
                                        rule_ip.append(value)
                                }
                        }
                }
                return rule_ip
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                if keyPath == "defaultPath" {
                        if self.defaultPath?.status == .satisfied{
                                if(lastPath == nil){
                                        NSLog("lastPath == nil")
                                        lastPath = self.defaultPath
                                }
                                NSLog("收到网络变更通知")
                                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                        self.startTunnel(options: nil){_ in}
                                }
                        }else{
                                NSLog("lastPath = defaultPath")
                                lastPath = defaultPath
                        }
                }
        }
}
//
//extension PacketTunnelProvider:IosLibVpnDelegateProtocol{
//        func log(_ str: String?) {
//                NSLog("---=>:\(str!)")
//        }
//}
