//
//  VpnManager.swift
//  youPipe
//
//  Created by wsli on 2019/5/23.
//  Copyright © 2019 ribencong. All rights reserved.
//


import Foundation
import NetworkExtension

class VpnManager{
        static let shared = VpnManager()
        var manager:NEVPNManager? = nil
        
        init() {
        }
        
        deinit {
        }
        
        func GetVPNStatus() ->(statusStr: String, enabled:Bool){
                if self.manager == nil{
                        return ("connect", true)
                }
                
                var str:String = "connect"
                var ok:Bool = true
                
                switch self.manager!.connection.status {
                case .connected:
                        str = "disconnect"
                        break
                case .connecting, .reasserting:
                        str="connecting"
                        ok = false
                        break
                case .disconnecting:
                        str="disconnecting"
                        ok = false
                        break
                case .disconnected, .invalid:
                        break
                @unknown default:
                        break
                }
                
                return (str, ok)
        }
        
        func ChangeStatus() throws{
                
                if self.manager == nil{
                        createManager()
                }
                
                let status = self.manager!.connection.status
                if status == .connected{
                        try self.disconnect()
                }else if status == .disconnected{
                        try self.connect()
                }else{
                        return
                }
        }
        
        func ReLoad(){
                
                NETunnelProviderManager.loadAllFromPreferences{
                        (ms, err) in
                        guard let vpnManagers = ms else{
                                print("no vpn manager -=>:", err.debugDescription)
                                return
                        }
                        
                        if vpnManagers.count == 0{
                                print("vpn manager count is zero-=>:")
                                return
                        }
                        
                        self.manager = vpnManagers[0]
                        
                        if vpnManagers.count > 1{
                                for i in 1 ..< vpnManagers.count{
                                        vpnManagers[i].removeFromPreferences{
                                                (err) in
                                                print(err.debugDescription)
                                        }
                                }
                        }
                }
        }
        
        func createManager() {
                let newManager = NETunnelProviderManager()
                newManager.protocolConfiguration = NETunnelProviderProtocol()
                newManager.localizedDescription = "YouPipe VPN"
                newManager.protocolConfiguration?.serverAddress = "YouPipe Blockchain Miner"
                self.manager = newManager
                self.manager?.saveToPreferences { (err) in
                        guard err == nil else{
                                print("Save to preferences err -=>:", err.debugDescription)
                                return
                        }
                        self.manager?.loadFromPreferences{ (err) in
                                print("Load again after save to prefere -=>:", err.debugDescription)
                        }
                }
        }
        
        func connect() throws{
                guard let m = self.manager else{
                        throw YouPipeError.NoTunManagerErr
                }
                m.isEnabled = true
                try m.connection.startVPNTunnel()
        }
        
        func disconnect()throws{
                guard let m = self.manager else{
                        throw YouPipeError.NoTunManagerErr
                }
                m.connection.stopVPNTunnel()
        }
}
