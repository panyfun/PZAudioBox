//
//  PZAudioRecorder.m
//  PZAudioRecorderDemo
//
//  Created by Pany on 2018/6/28.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import "PZAudioRecorder.h"

#import <AVFoundation/AVFoundation.h>

#import "PZAudioTranscoder.h"

static NSInteger const kPZAudioRecorderRateDefault = 11025;

@interface PZAudioRecorder () <AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *avRecorder;
@property (nonatomic, strong) NSString *audioDic;
@property (nonatomic, strong) NSString *cafPath;
@property (nonatomic, strong) NSString *mp3Path;
@property (nonatomic) NSInteger recordRate;

@property (nonatomic, strong) PZAudioTranscoder *transcoder;

@end

@implementation PZAudioRecorder

- (instancetype)init {
    return [self initWithAudioSetting:nil];
}

- (instancetype)initWithAudioSetting:(NSDictionary *)settings {
    NSMutableDictionary *settingDic = [NSMutableDictionary dictionary];
    [settingDic setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    [settingDic setObject:@(kPZAudioRecorderRateDefault) forKey:AVSampleRateKey];
    [settingDic setObject:@(2) forKey:AVNumberOfChannelsKey];
    [settingDic setObject:@(16) forKey:AVLinearPCMBitDepthKey];
    [settingDic setObject:[NSNumber numberWithInt:AVAudioQualityMedium] forKey:AVEncoderAudioQualityKey];
    if (settingDic) {
        [settingDic setValuesForKeysWithDictionary:settings];
    }
    
    NSString *dicPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"PZAudioData"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dicPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dicPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if (self = [super init]) {
        NSError *sessionError;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        
        _audioDic = dicPath;
        NSString *fileName = [NSString stringWithFormat:@"tmp%.0f.caf", [[NSDate date] timeIntervalSince1970]*1000];
        _cafPath = [_audioDic stringByAppendingPathComponent:fileName];
        
        _avRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:_cafPath] settings:settingDic error:nil];
        _avRecorder.delegate = self;
        _avRecorder.meteringEnabled = YES;
        [_avRecorder prepareToRecord];
        
        _recordRate = [[settingDic objectForKey:AVSampleRateKey] intValue];
        _state = PZAudioRecorderStatus_Idle;
        _concurrenceTrans = YES;
    }
    return self;
}

- (void)beginRecord {
    if (_state == PZAudioRecorderStatus_Idle) {
        _state = PZAudioRecorderStatus_Recording;
        
        if (_transcoder) {
            [[NSFileManager defaultManager] removeItemAtPath:_cafPath error:nil];
            _transcoder = nil;
        }
        
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        NSString *fileName = [NSString stringWithFormat:@"%.0f.mp3", [[NSDate date] timeIntervalSince1970]*1000];
        _mp3Path = [_audioDic stringByAppendingPathComponent:fileName];
        [_avRecorder record];
        
        _transcoder = [PZAudioTranscoder new];
        _transcoder.cafPath = _cafPath;
        _transcoder.mp3Path = _mp3Path;
        _transcoder.audioRate = _recordRate;
        _transcoder.fileIntegrity = !_concurrenceTrans;
        if (_concurrenceTrans) {
            [_transcoder transCode];
        }
    }
}

- (void)endRecord {
    [_avRecorder stop];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)stopRecord:(void(^)(BOOL succ, NSString *path))completion {
    if (_state == PZAudioRecorderStatus_Recording) {
        _transcoder.completion = ^(BOOL succ, NSString *path) {
            if (completion) {            
                completion(succ, path);
            }
        };
        [self endRecord];
    }
}

- (void)cancelRecord {
    if (_state == PZAudioRecorderStatus_Recording) {
        [_transcoder cancelTranscode];
        [self endRecord];
        [[NSFileManager defaultManager] removeItemAtPath:_cafPath error:nil];
    }
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    _transcoder.fileIntegrity = YES;
    if (!_concurrenceTrans) {
        [_transcoder transCode];
    }
}

#pragma mark - Accessor
- (void)setConcurrenceTrans:(BOOL)concurrenceTrans {
    if (_concurrenceTrans != concurrenceTrans && _state == PZAudioRecorderStatus_Idle) {
        _concurrenceTrans = concurrenceTrans;
    }
}

@end
