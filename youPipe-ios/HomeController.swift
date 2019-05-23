//
//  FirstViewController.swift
//  youPipe-ios
//
//  Created by Li Wansheng on 2019/4/24.
//  Copyright © 2019年 ribencong. All rights reserved.
//

import UIKit

class HomeController: UIViewController {

        @IBOutlet weak var connectButton: UIButton!
        
        required init?(coder aDecoder: NSCoder) {
                super.init(coder: aDecoder)
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(onVpnStatusChanged),
                                                       name: NSNotification.Name(rawValue: kProxyServiceVPNStatusNotification),
                                                       object: nil)
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
        }
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
               self.onVpnStatusChanged()
        }

        
        
        @IBAction func ConnectAction(_ sender: UIButton) {
                do{
                        if(VpnManager.shared.vpnStatus == .off){
                                try VpnManager.shared.connect()
                        }else{
                                try VpnManager.shared.disconnect()
                        }
                }catch let err{
                        print(err)//TODO::
                }
        }
        
        @objc func onVpnStatusChanged(){
                let status = VpnManager.shared.vpnStatus
                switch status {
                case .connecting:
                        connectButton.setTitle("connecting", for: UIControl.State())
                case .disconnecting:
                        connectButton.setTitle("disconnect", for: UIControl.State())
                case .on:
                        connectButton.setTitle("Disconnect", for: UIControl.State())
                case .off:
                        connectButton.setTitle("Connect", for: UIControl.State())
                        
                }
                connectButton.isEnabled = [VPNStatus.on,VPNStatus.off].contains(VpnManager.shared.vpnStatus)
        }
        
}

