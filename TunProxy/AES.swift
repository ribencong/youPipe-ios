//
//  AES.swift
//  TunProxy
//
//  Created by wsli on 2019/6/13.
//  Copyright © 2019 com.ribencong.youPipe. All rights reserved.
//

import Foundation

class AES:NSObject{
        
        private var iv:Data
        private var key:Data
        
        enum AESError: Swift.Error {
                case keyGeneration(status: Int)
                case cryptoFailed(status: CCCryptorStatus)
                case badKeyLength
                case badInputVectorLength
        }
        
        init(key:Data, iv:Data) throws{
                guard key.count == kCCKeySizeAES256 else{
                        throw AESError.badKeyLength
                }
                
                guard iv.count == kCCBlockSizeAES128 else{
                        throw AESError.badInputVectorLength
                }
                
                self.iv = iv
                self.key = key
                super.init()
        }
        
        func encrypt(_ digest: Data) throws -> Data{
                return try crypt(input: digest, operation: CCOperation(kCCEncrypt))
        }
        
        func decrypt(_ encrypted: Data) throws -> Data{
                return try crypt(input: encrypted, operation: CCOperation(kCCDecrypt))
        }
        
        private func crypt(input: Data, operation: CCOperation) throws -> Data {
                var outLength = Int(0)
                var outBytes = [UInt8](repeating: 0, count: input.count + kCCBlockSizeAES128)
                
                var status: CCCryptorStatus = CCCryptorStatus(kCCSuccess)
                
                input.withUnsafeBytes { (encryptedBytes: UnsafePointer<UInt8>!) -> () in
                        iv.withUnsafeBytes { (ivBytes: UnsafePointer<UInt8>!) in
                                key.withUnsafeBytes { (keyBytes: UnsafePointer<UInt8>!) -> () in
                                        status = CCCrypt(operation,
                                                         CCAlgorithm(kCCAlgorithmAES),            // algorithm
                                                CCOptions(kCCModeCFB + ccNoPadding),           // options
                                                keyBytes,                                   // key
                                                key.count,                                  // keylength
                                                ivBytes,                                    // iv
                                                encryptedBytes,                             // dataIn
                                                input.count,                                // dataInLength
                                                &outBytes,                                  // dataOut
                                                outBytes.count,                             // dataOutAvailable
                                                &outLength)                                 // dataOutMoved
                                }
                        }
                }
                guard status == kCCSuccess else {
                        throw AESError.cryptoFailed(status: status)
                }
                return Data(bytes: UnsafePointer<UInt8>(outBytes), count: outLength)
        }
}

extension AES{
        
        static func randomData(length: Int) -> Data {
                var data = Data(count: length)
                let status = data.withUnsafeMutableBytes { mutableBytes in
                        SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes)
                }
                assert(status == Int32(0))
                return data
        }
        
        static func randomIV() -> Data {
                return randomData(length: kCCBlockSizeAES128)
        }
}
