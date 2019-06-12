//
//  Adapter.swift
//  TunProxy
//
//  Created by wsli on 2019/6/4.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation

public protocol Adapter: class{
        var ID:Int32? { get set }
        func readData() throws -> Data 
        func writeData(data: Data) throws
        func byePeer()
}
