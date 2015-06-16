//
//  XCDecodeJson.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/10.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "DecodeJson.h"
#import "GTMBase64.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

@implementation DecodeJson

+(NSString*) decryptUseDES:(NSString*)cipherText key:(NSString*)key
{
    // 利用 GTMBase64 解碼 Base64 字串
    NSData* cipherData = [GTMBase64 decodeString:cipherText];
    unsigned char buffer[1024*10];
    memset(buffer, 0, sizeof(char));
    size_t numBytesDecrypted = 0;
    // IV 偏移量不需使用
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          [key UTF8String],
                                          kCCKeySizeDES,
                                          nil,
                                          [cipherData bytes],
                                          [cipherData length],
                                          buffer,
                                          1024*10,
                                          &numBytesDecrypted);
    NSString* plainText = nil;
    if (cryptStatus == kCCSuccess) {
        NSData* data = [NSData dataWithBytes:buffer length:(NSUInteger)numBytesDecrypted];
        plainText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ;
    }
    return plainText;
}
+(NSString *)XCmdMd5String:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ]; 
}

+(BOOL) validateEmail: (NSString *) candidate
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:candidate];
}

+(NSString*)getDeviceTypeByType:(int)nType
{
    if (nType>0 && nType <= 2000)
    {
        return XCLocalized(@"ipcType");
        //IPC
    }
    else if(nType>2000 && nType <= 4000)
    {
        if (nType <= 2100)
        {
            return XCLocalized(@"DVR4");
        }
        else if(nType<=2200)
        {
            return XCLocalized(@"DVR8");
        }
        else if(nType <= 2300)
        {
            return XCLocalized(@"DVR16");
        }
        else if(nType <= 2400)
        {
            return XCLocalized(@"DVR24");
        }
        else if(nType <= 2500)
        {
            return XCLocalized(@"DVR32");
        }
        else
        {
            return XCLocalized(@"DVRError");
        }
        //DVR
    }
    else if(nType>4000 && nType <= 6000)
    {
        //NVR
        if (nType <= 4100)
        {
            return XCLocalized(@"NVR4");
        }
        else if(nType<=4200)
        {
            return XCLocalized(@"NVR8");
        }
        else if(nType <= 4300)
        {
            return XCLocalized(@"NVR16");
        }
        else if(nType <= 4400)
        {
            return @"NVR-25";
        }
        else if(nType <= 4500)
        {
            return XCLocalized(@"NVR32");
        }
        else if(nType <=4600)
        {
            return @"NVR-25";
        }
        else
        {
            return XCLocalized(@"NVRError");
        }
    }
    return XCLocalized(@"deviceNULL");
}

@end
