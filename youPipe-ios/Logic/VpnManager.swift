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

class VpnManager{
        static let Shared = VpnManager()
}
