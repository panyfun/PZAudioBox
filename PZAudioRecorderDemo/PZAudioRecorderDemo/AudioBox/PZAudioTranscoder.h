//
//  PZAudioTranscodeer.h
//  PZAudioRecorderDemo
//
//  Created by Pany on 2018/6/29.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^PZAudioTranscodeComplete)(BOOL succ, NSString *path);

@interface PZAudioTranscoder : NSObject

@property (nonatomic, copy) NSString *cafPath;
@property (nonatomic, copy) NSString *mp3Path;
@property (nonatomic) NSInteger audioRate;
@property (nonatomic, copy) PZAudioTranscodeComplete completion;

/**
 文件是否完整 [default:YES]
 文件直接转码，在transCode前设置YES
 边录边转时，在transCode前设置NO，录完后设置为YES
 */
@property (nonatomic) BOOL fileIntegrity;


/**
 开始转码
 completion可适当滞后设置，其它参数务必调用前设置
 @return 是否开启成功
 */
- (BOOL)transCode;
- (void)cancelTranscode;

@end
