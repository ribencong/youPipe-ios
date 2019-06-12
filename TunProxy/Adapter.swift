//
//  Adapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation

public protocol Adapter: class{        
        func readData() throws -> Data 
        func write(data: Data) throws
        func byePeer()
}
