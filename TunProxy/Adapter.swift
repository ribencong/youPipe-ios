//
//  Adapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation

public protocol Adapter: class{ 
        func readData(tag:Int)
        func write(data:Data, tag:Int)
        func byePeer()
}
