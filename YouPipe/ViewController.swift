//
//  ViewController.swift
//  YouPipe
//
//  Created by wsli on 2019/6/1.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

        @IBOutlet weak var BlockChainAddress: UITextField!
        @IBOutlet weak var BlockChainCipher: UITextView!
        @IBOutlet weak var connectButton: UIButton!
        @IBOutlet weak var createAccountBtn: UIButton!
        @IBOutlet weak var LicenseStartTime: UITextField!
        @IBOutlet weak var LicenseEndTime: UITextField!
        @IBOutlet weak var LicenseArea: UITextView!
        @IBOutlet weak var importBtn: UIButton!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                do {
                        createAccountBtn.isHidden = true
                        let (addr, cipher) = try YouPipeService.shared.LoadBlockChainAccount()
                        BlockChainAddress.text = addr
                        BlockChainCipher.text = cipher
                }catch{
                        createAccountBtn.isHidden = false
                }
                
                
        }

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
        
        @IBAction func importLicense(_ sender: Any) {
        }
        
}

