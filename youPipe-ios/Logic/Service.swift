//
//  Service.swift
//  youPipe-ios
//
//  Created by Li Wansheng on 2019/4/24.
//  Copyright © 2019年 ribencong. All rights reserved.
//

import Foundation

let KEY_FOR_SWITCH_STATE = "KEY_FOR_SWITCH_STATE"
let KEY_FOR_YOUPIPE_MODEL = "KEY_FOR_YOUPIPE_MODEL"

class Service: NSObject {
        var defaults = UserDefaults.standard
        
        var IsTurnOn:Bool = false
        var IsGlobal:Bool = false
        
        private override init(){
                super.init()
                
                self.IsTurnOn = defaults.bool(forKey: KEY_FOR_SWITCH_STATE)
                self.IsGlobal = defaults.bool(forKey: KEY_FOR_YOUPIPE_MODEL)
        }
        
        class var sharedInstance: Service {
                struct Static {
                        static let instance: Service = Service()
                }
                return Static.instance
        }
        
        public func updateProxyMode() {
                
//                NSString *proxyMode = [[NSUserDefaults standardUserDefaults] objectForKey:kProxyModeKey];
//                if (proxyMode == nil || [proxyMode isEqualToString:@"pac"]) {
//                        [AppProxyCap setPACURL:@];
//                } else if ([proxyMode isEqualToString:@"global"]) {
//                        [AppProxyCap setProxy:AppProxy_SOCKS Host:@"127.0.0.1" Port:1080];
//                } else{
//                        [AppProxyCap setNoProxy];
//                }
        }

}
