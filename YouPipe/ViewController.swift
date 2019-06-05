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
                        createAccountBtn.tag = 1
                        
                        let licObj = try YouPipeService.shared.LoadLicense()
                        LicenseStartTime.text = licObj?.start
                        LicenseEndTime.text = licObj?.end
                        importBtn.tag = 1
                        importBtn.titleLabel?.text="更新license"
                        
                }catch YPError.NoValidAccount{
                        createAccountBtn.tag = 0
                }catch YPError.NoValidLicense{
                        importBtn.tag = 0
                        importBtn.titleLabel?.text="创建license"
                }catch{
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
        
        @IBAction func importLicense(_ sender: UIButton) {
                if sender.tag == 0{//Import license
                        
                       guard let licStr = LicenseArea.text,  licStr.lengthOfBytes(using: .utf8) > 64 else{
                                showTips(msg: "Too short", parent: self)
                                return
                        }
                        do {
                                let licObj = try YouPipeService.shared.ImportLicense(data: licStr)
                                LicenseStartTime.text = licObj?.start
                                LicenseEndTime.text = licObj?.end
                                importBtn.tag = 1
                        } catch{
                                showTips(msg: "Import license failed", parent: self)
                        }
                        
                }else{//Update License
                        
                }
        }
        
        @IBAction func CreateAccount(_ sender: UIButton) {
                if sender.tag == 0 {
                        showPasswordUI(parent: self){
                                passwd in
                                
                                if passwd.lengthOfBytes(using: .utf8) < 8{
                                        showTips(msg: "Too short", parent: self)
                                        return
                                }
                                do {
                                   let (adr, cipher) = try YouPipeService.shared.CreateAccount(password: passwd)
                                        self.BlockChainAddress.text = adr
                                        self.BlockChainCipher.text = cipher
                                        sender.tag = 1
                                }catch{
                                        showTips(msg: "创建账号失败", parent: self)
                                }
                        }
                        
                }else{
                        //Replace current address, do it later.
                }
        }
}



func showPasswordUI(parent:UIViewController, action:@escaping (String)->Void ){
        let alert = UIAlertController(title: "Input the password", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField(configurationHandler: { textField in
                textField.placeholder = "Input your password here..."
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { ac in
                if let name = alert.textFields?.first?.text {
                        action(name)
                }
        }))
        
        parent.present(alert, animated: true)
}

func showTips(msg:String, parent:UIViewController){
        let alert = UIAlertController(title: "Tips", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        parent.present(alert, animated: true)
}
