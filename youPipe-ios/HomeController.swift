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
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        func observeStatus() {
                NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange,
                                                       object: nil,
                                                       queue: OperationQueue.main,
                                                       using:  updateConnectButton)
        }
        
        func stopObservingStatus() {
               NotificationCenter.default.removeObserver(self,
                                                         name: NSNotification.Name.NEVPNStatusDidChange,
                                                         object: nil)
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
        }
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                stopObservingStatus()
                VpnManager.shared.ReLoad()
                observeStatus()
        }
        
        @IBAction func ConnectAction(_ sender: UIButton) { 
                do {
                        try VpnManager.shared.ChangeStatus()
                        
                }catch let err{
                        
                        let alert = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle:.alert)
                       alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        
                       self.present(alert, animated:true)
                }
               
        }
        
        func updateConnectButton(_ noti:Notification){
                let (status, enabled) = VpnManager.shared.GetVPNStatus()
                connectButton.setTitle(status, for: UIControl.State())
                connectButton.isEnabled = enabled
        }
}

