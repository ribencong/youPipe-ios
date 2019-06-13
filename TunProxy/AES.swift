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
                
                var cryptorRef:CCCryptorRef? = nil;
                var status: CCCryptorStatus = CCCryptorStatus(kCCSuccess)
                
                iv.withUnsafeBytes{ (ivBytes: UnsafePointer<UInt8>?) -> () in
                        key.withUnsafeBytes{ (keyBytes: UnsafePointer<UInt8>?) -> () in
                                status = CCCryptorCreateWithMode(operation,
                                                        CCMode(kCCModeCFB),
                                                        CCAlgorithm(kCCAlgorithmAES),
                                                        CCPadding(ccNoPadding),
                                                        ivBytes,
                                                        keyBytes,
                                                        kCCKeySizeAES256,
                                                        nil,
                                                        0,
                                                        0,
                                                        0,
                                                        &cryptorRef)
                        }
                }
                
                guard status == kCCSuccess else {
                        throw AESError.cryptoFailed(status: status)
                }
                defer { _ = CCCryptorRelease(cryptorRef!)}
                
                
                let needed = CCCryptorGetOutputLength(cryptorRef!, input.count, true)
                var result = Data.init(count: needed)
                var updateLen: size_t = 0
                let rescount = result.count
                input.withUnsafeBytes{ (inputBytes: UnsafePointer<UInt8>?) -> () in
                        result.withUnsafeMutableBytes{ (resultBytes:UnsafeMutablePointer<UInt8>) -> () in
                                 status = CCCryptorUpdate(cryptorRef, inputBytes, input.count, resultBytes, needed, &updateLen)
                        }
                }
                guard status == noErr else { throw AESError.cryptoFailed(status: status)}
                
                
                var finalLen: size_t = 0
                status = result.withUnsafeMutableBytes { resultBytes in
                        return CCCryptorFinal(cryptorRef!, resultBytes + updateLen,
                                               rescount - updateLen,
                                               &finalLen)
                }
                guard status == noErr else { throw AESError.cryptoFailed(status: status) }
                result.count = updateLen + finalLen
                
                return result as Data
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
