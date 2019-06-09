//
//  YPError.swift
//  TunProxy
//
//  Created by wsli on 2019/6/3.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation
enum YPError: Error{
        case SystemError,
        BusinessError,
        NoValidBootNode,
        NoValidAccount,
        AccountCreateError,
        NoValidLicense,
        OpenPrivateKeyErr,
        GenAesKeyErr,
        ED25519SignErr,
        VPNParamLost,
        HttpProxyFailed,
        JsonPackError,
        HandShakeErr,
        InvalidAesKeyErr,
        InvalidSignBill,
        InvalidSign,
        InvalidMineral,
        SignBillVerifyFailed,
        BillOverFlowUsed,
        SignBillProofErr,
        PayChannelHasClosed
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
                case .HttpProxyFailed:
                        return NSLocalizedString("Failed to start http proxy server".localized, comment: "Pipe Error")
                case .JsonPackError:
                         return NSLocalizedString("Pack Json array to data failed".localized, comment: "Pipe Error")
                case .HandShakeErr:
                        return NSLocalizedString("Hand shake with socks server err".localized, comment: "Pipe Error")
                case .InvalidAesKeyErr:
                        return NSLocalizedString("Aes key invalid".localized, comment: "Pipe Error")
                case .InvalidSignBill:
                        return NSLocalizedString("Invalid Sign Bill".localized, comment: "Pipe Error")
                case .InvalidSign:
                        return NSLocalizedString("Signature invalid".localized, comment: "Pipe Error")
                case .InvalidMineral:
                        return NSLocalizedString("Mineral data in bill is invalid".localized, comment: "Pipe Error")
                case .SignBillVerifyFailed:
                        return NSLocalizedString("Sign bill verfiy failed".localized, comment: "Pipe Error")
                case .BillOverFlowUsed:
                        return NSLocalizedString("Flow amount in bill is over flow of record".localized, comment: "Pipe Error")
                case .SignBillProofErr:
                        return NSLocalizedString("Generate proof of floww bill failed".localized, comment: "Pipe Error")
                case .PayChannelHasClosed:
                        return NSLocalizedString("Payment channel has been closed".localized, comment: "Pipe Error")
                }
        }
}

extension String {
        var localized: String {
                return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
        }
}
