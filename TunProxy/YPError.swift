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
        AccountCreateError,NoValidLicense, OpenPrivateKeyErr, GenAesKeyErr,
        ED25519SignErr, VPNParamLost, JsonEncodeErr
}

extension YPError: LocalizedError {
        public var errorDescription: String? {
                switch self { 
                case .SystemError:
                        return NSLocalizedString("System error".localized, comment: "System Error")
                case .BusinessError:
                        return NSLocalizedString("Business error".localized, comment: "Business Error")
                case .NoValidBootNode:
                        return NSLocalizedString("No valid boot strap miner node".localized, comment: "Pipe Error")
                case .NoValidAccount:
                        return NSLocalizedString("No valid block chain address".localized, comment: "Pipe Error")
                case .AccountCreateError:
                        return NSLocalizedString("Create new block chain account failed".localized, comment: "Pipe Error")
                case .NoValidLicense:
                        return NSLocalizedString("No valid license".localized, comment: "Pipe Error")
                case .OpenPrivateKeyErr:
                        return NSLocalizedString("Failed to open self account".localized, comment: "Pipe Error")
                case .GenAesKeyErr:
                        return NSLocalizedString("Failed to generate aes key with peer address".localized, comment: "Pipe Error")
                case .ED25519SignErr:
                        return NSLocalizedString("Failed to sign data by ed25519 private key".localized, comment: "Pipe Error")
                case .VPNParamLost:
                        return NSLocalizedString("Not enough parameter to connecto miner node".localized, comment: "Pipe Error")
                case .JsonEncodeErr:
                        return NSLocalizedString("Packet Json array error".localized, comment: "Pipe Error")
                }
        }
}

extension String {
        var localized: String {
                return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
        }
}
