//
//  YPError.swift
//  TunProxy
//
//  Created by wsli on 2019/6/3.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
enum YPError:Error{
        case SystemError, BusinessError, NoValidBootNode, NoValidAccount,
        AccountCreateError,NoValidLicense
}
