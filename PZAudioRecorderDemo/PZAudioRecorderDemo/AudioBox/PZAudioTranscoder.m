//
//  PZAudioTranscodeer.m
//  PZAudioRecorderDemo
//
//  Created by Pany on 2018/6/29.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import "PZAudioTranscoder.h"

#import <lame/lame.h>

@interface PZAudioTranscoder ()

@property (nonatomic) dispatch_queue_t transcodeQueue;
@property (nonatomic) BOOL cancel;

@end

@implementation PZAudioTranscoder

- (instancetype)init {
    if (self = [super init]) {
        _transcodeQueue = dispatch_queue_create("com.pany.PZAudioTrancoder.transcode", NULL);
        _fileIntegrity = YES;
    }
    return self;
}

- (void)parallelTranscodeCaf:(NSString *)cafPath toMP3:(NSString *)mp3Path withSampleRate:(int)sampleRate complete:(void(^)(BOOL succ, NSString *path))completion {
    __weak typeof(self) weakself = self;
    dispatch_async(_transcodeQueue, ^{
        @try {
            
            int read, write;
            
            FILE *pcm = fopen([cafPath cStringUsingEncoding:NSASCIIStringEncoding], "rb");
            FILE *mp3 = fopen([mp3Path cStringUsingEncoding:NSASCIIStringEncoding], "wb+");
            
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE * 2];
            unsigned char mp3_buffer[MP3_SIZE];
            
            lame_t lame = lame_init();
            lame_set_in_samplerate(lame, sampleRate);
            lame_set_VBR(lame, vbr_default);
            lame_init_params(lame);
            
            long curpos;
            BOOL isSkipPCMHeader = NO;
            
            do {
                curpos = ftell(pcm);
                long startPos = ftell(pcm);
                fseek(pcm, 0, SEEK_END);
                long endPos = ftell(pcm);
                long length = endPos - startPos;
                fseek(pcm, curpos, SEEK_SET);
                
                if (length > PCM_SIZE * 2 * sizeof(short int)) {
                    
                    if (!isSkipPCMHeader) {
                        //Uump audio file header, If you do not skip file header
                        //you will heard some noise at the beginning!!!
                        fseek(pcm, 4 * 1024, SEEK_CUR);
                        isSkipPCMHeader = YES;
                    }
                    
                    read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                    fwrite(mp3_buffer, write, 1, mp3);
                } else {
                    [NSThread sleepForTimeInterval:0.05];
                }
                
            } while (!weakself.fileIntegrity || weakself.cancel);
            
            read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
            write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            
            lame_mp3_tags_fid(lame, mp3);
            
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
        }
        @catch (NSException *exception) {
            NSLog(@"%@", [exception description]);
            if (completion) {
                completion(NO, nil);
            }
        }
        @finally {
            if (completion) {
                completion(!self.cancel, self.cancel ? nil : mp3Path);
            }
        }
    });
}

- (void)transcodeCaf:(NSString *)cafPath toMP3:(NSString *)mp3Path withSampleRate:(int)sampleRate complete:(void(^)(BOOL succ, NSString *path))completion {
    dispatch_async(_transcodeQueue, ^{
        @try {
            int read, write;
            
            FILE *pcm = fopen([cafPath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
            fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
            FILE *mp3 = fopen([mp3Path cStringUsingEncoding:1], "wb+");  //output 输出生成的Mp3文件位置
            
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE*2];
            unsigned char mp3_buffer[MP3_SIZE];
            
            lame_t lame = lame_init();
            lame_set_num_channels(lame,1);//设置1为单通道，默认为2双通道
            lame_set_in_samplerate(lame, sampleRate);
            lame_set_VBR(lame, vbr_default);
            lame_init_params(lame);
            
            do {
                
                read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
                if (read == 0) {
                    write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                    
                } else {
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                }
                
                fwrite(mp3_buffer, write, 1, mp3);
                
            } while (read != 0 || self.cancel);
            
            lame_mp3_tags_fid(lame, mp3);
            
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception description]);
            if (completion) {
                completion(NO, nil);
            }
        }
        @finally {
            if (completion) {
                completion(!self.cancel, self.cancel ? nil : mp3Path);
            }
        }
    });
}

- (BOOL)transCode {
    if (![[NSFileManager defaultManager] fileExistsAtPath:_cafPath]
        || (_fileIntegrity && [NSData dataWithContentsOfFile:_cafPath].length == 0)
        || ![_mp3Path isKindOfClass:[NSString class]]
        || _audioRate == 0) {
        NSLog(@"参数错误");
        return NO;
    }
    _cancel = NO;
    NSString *dicPath = [_mp3Path stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dicPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dicPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    __weak typeof(self) weakSelf = self;
    if (_fileIntegrity) {
        [self transcodeCaf:_cafPath toMP3:_mp3Path withSampleRate:(int)_audioRate complete:^(BOOL succ, NSString *path) {
            if (weakSelf.completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.completion(succ, path);
                });
            }
        }];
    } else {
        [self parallelTranscodeCaf:_cafPath toMP3:_mp3Path withSampleRate:(int)_audioRate complete:^(BOOL succ, NSString *path) {
            if (weakSelf.completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.completion(succ, path);
                });
            }
        }];
    }
    return YES;
}

- (void)cancelTranscode {
    _cancel = YES;
}

@end
