//
//  PZAudioRecorder.h
//  PZAudioRecorderDemo
//
//  Created by Pany on 2018/6/28.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    PZAudioRecorderStatus_Idle,
    PZAudioRecorderStatus_Recording,
    PZAudioRecorderStatus_Transcoding,
} PZAudioRecorderStatus;


/**
 Recorder没有采用单例形式
 主要是为了让每个Recorder能够使用独立的录音配置
 */
@interface PZAudioRecorder : NSObject

@property (nonatomic, readonly) PZAudioRecorderStatus state;

/**
 录音的同时进行转码 [default:YES]
 PZAudioRecorderStatus_Idle状态才能修改
 */
@property (nonatomic) BOOL concurrenceTrans;

// settings为自定义参数，不带则使用默认设置
- (instancetype)init;
- (instancetype)initWithAudioSetting:(NSDictionary *)settings;

- (void)beginRecord;
- (void)stopRecord:(void(^)(BOOL succ, NSString *path))completion;
- (void)cancelRecord;

@end
