//
//  ViewController.m
//  PZAudioRecorderDemo
//
//  Created by Pany on 2018/6/29.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import "ViewController.h"

#import "PZAudioRecorder.h"

@interface ViewController ()

@property (nonatomic, strong) PZAudioRecorder *recorder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _recorder = [PZAudioRecorder new];
}

- (IBAction)recordBtnAction:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    if (sender.selected) {
        [_recorder beginRecord];
    } else {
        [_recorder stopRecord:^(BOOL succ, NSString *path) {
            NSLog(@"record finish %@", path);
        }];
    }
}

@end
