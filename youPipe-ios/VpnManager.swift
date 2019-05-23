//
//  VpnManager.swift
//  youPipe
//
//  Created by wsli on 2019/5/23.
//  Copyright © 2019 ribencong. All rights reserved.
//

import Foundation
import NetworkExtension


enum VPNStatus{
        case off
        case connecting
        case on
        case disconnecting
}


let kProxyServiceVPNStatusNotification = "kProxyServiceVPNStatusNotification"

class VpnManager{
        static let shared = VpnManager()
        var TPManager:NETunnelProviderManager? = nil
        fileprivate(set) var vpnStatus = VPNStatus.off
        
        init(){
                
                NETunnelProviderManager.loadAllFromPreferences { (ms, err) in
                        guard let managers = ms else{
                                exit(-1)
                        }
                        
                        if managers.count > 0 {
                                self.TPManager = managers[0]
                                self.delDupConfig(managers)
                        }else{
                                self.TPManager = self.createProviderManager()
                        }
                        
                        NotificationCenter.default.addObserver(forName:NSNotification.Name.NEVPNStatusDidChange,
                                                               object: self.TPManager!.connection,
                                                               queue: OperationQueue.main,
                                                               using:self.updateVPNStatus)
                }
        }
        
        func createProviderManager() -> NETunnelProviderManager {
                
                let m = NETunnelProviderManager()
                let conf  = NETunnelProviderProtocol()
                conf.serverAddress = ""
                m.protocolConfiguration = conf
                m.localizedDescription = "YouPipe"
                m.isEnabled = true
                m.saveToPreferences { (err) in
                        guard err == nil else{
                                print("---save to preference--->\n", err!)
                                return
                        }
                }
                
                return m
        }
        
        func delDupConfig(_ arrays:[NETunnelProviderManager]){
                if (arrays.count)>1{
                        for i in 0 ..< arrays.count{
                                print("Del DUP Profiles")
                                arrays[i].removeFromPreferences(completionHandler: { (error) in
                                        if(error != nil){print(error.debugDescription)}
                                })
                        }
                }
        }
        
        func updateVPNStatus(_ noti:Notification){
                print("---update vpn status--->", noti.debugDescription)
                
                guard let m = self.TPManager else {
                        return
                }
                
                switch m.connection.status {
                case .connected:
                        self.vpnStatus = .on
                case .connecting, .reasserting:
                        self.vpnStatus = .connecting
                case .disconnecting:
                        self.vpnStatus = .disconnecting
                case .disconnected, .invalid:
                        self.vpnStatus = .off
                @unknown default:
                        self.vpnStatus = .off
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: kProxyServiceVPNStatusNotification), object: nil)
        }
        
        func connect() throws{
                try self.TPManager?.connection.startVPNTunnel()
        }
        func disconnect() throws{
                try self.TPManager?.connection.startVPNTunnel()
        }
}
