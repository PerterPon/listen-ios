//
//  LISRadioData.m
//  listen-ios
//
//  Created by PerterPon on 2019/8/18.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "LISRadioData.h"
#import "LISEtc.h"
#import <NSString+MD5.h>

@interface LISRadioData()
{
    BOOL queuing;
    int receiveTimes;
    NSString *radioName;
    int doneFregmentId;
    int currentFregmentId;
    int baselineFregmentId;
}

@end

@implementation LISRadioData

static LISRadioData *radioData;

+(instancetype) shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        radioData = [[self alloc] init];
    });
    
    return radioData;
}

-(void) initData {
    self.data = [[NSMutableData alloc] init];
    queuing = NO;
    receiveTimes = 0;
    doneFregmentId = 0;
    baselineFregmentId = 0;
}

-(void) startWith:(NSString *)name {
    if (YES == queuing) {
        [self stop];
    }
    radioName = name;
    [self.data resetBytesInRange:NSMakeRange(0, [self.data length])];
    [self.data setLength:0];

    LISEtc *etc = [LISEtc shareInstance];
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval timestamp = round([date timeIntervalSince1970]*1000);
    
    NSString *sign = [[NSString stringWithFormat:@"%@%f", etc.salt, timestamp] MD5Digest];
    NSString *urlString = [NSString stringWithFormat:@"%@:%d/radio/register?timestamp=%f&sign=%@&name=%@", etc.httpsDomain, etc.port, timestamp, sign, name];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    receiveTimes = 0;
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 6.0;
    sessionConfig.timeoutIntervalForResource = 6.0;
    
    NSURLSessionDataTask *task = [session
                                  dataTaskWithRequest:request
                                  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                      if (nil != error) {
                                          NSTimer *timer = [NSTimer timerWithTimeInterval:3.0f repeats:NO block:^(NSTimer * _Nonnull timer) {
                                              [self startWith:name];
                                          }];
                                          self.timer = timer;
                                          [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
                                          return;
                                      }

                                      NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                                      if (nil == dict) {
                                          return;
                                      }

                                      NSDictionary *radioData = dict[@"data"];
                                      struct RadioInfo currentRadioInfo;
                                      currentRadioInfo.codecs = radioData[@"codecs"];
                                      currentRadioInfo.duration = radioData[@"duration"];
                                      currentRadioInfo.timescale = radioData[@"timescale"];
                                      currentRadioInfo.mimeType = radioData[@"mimeType"];
                                      currentRadioInfo.sampleRate = radioData[@"sampleRate"];
                                      currentRadioInfo.baseUrl = radioData[@"baseUrl"];
                                      
                                      float timescale = [currentRadioInfo.timescale floatValue];
                                      float duration = [currentRadioInfo.duration floatValue];
                                      float fregmentDuration = duration / timescale;
                                      currentRadioInfo.fregmentDuration = [NSNumber numberWithFloat:fregmentDuration];
                                      self.radioInfo = currentRadioInfo;
                                      [self loadMediaFregmentWith:-1];
                                      [self startQueue];
                                  }];
    [task resume];
}

-(void) startQueue {
    NSNumber *duration = self.radioInfo.fregmentDuration;
    queuing = YES;
    if (self.timer) {
        [self.timer invalidate];
    }
    self.timer = [NSTimer timerWithTimeInterval:[duration doubleValue] repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self loadMediaFregmentWith:0];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    [self.timer fire];
}

-(void) loadMediaFregmentWith: (int)distance {
    int nowFregmentId;
    if (0 == currentFregmentId) {
        NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval time = [date timeIntervalSince1970];
        NSNumber *duration = self.radioInfo.fregmentDuration;
        int fregmentId = (int)((double)time / [duration doubleValue]) - 1 - distance;
        currentFregmentId = fregmentId;
    } else {
        currentFregmentId++;
    }
    
    if(0 == baselineFregmentId) {
        baselineFregmentId = currentFregmentId;
    }

    nowFregmentId = currentFregmentId;
    
    [self doLoadDataWithFregmentId:currentFregmentId :^(NSData *data) {
        self -> doneFregmentId = nowFregmentId;
        self -> baselineFregmentId = nowFregmentId + 1;
        [self.data appendData:data];
        if (0 == self -> receiveTimes++) {
            [self.delegate onFirstDataReceived];
        } else {
            [self.delegate onDataReceived];
        }
    } :^{
        int needReloadFregmentId = 0;
        if (self -> baselineFregmentId == self -> doneFregmentId + 1) {
            if (nowFregmentId == self -> doneFregmentId + 1 || nowFregmentId == self -> doneFregmentId + 2) {
                // load
                needReloadFregmentId = self -> baselineFregmentId;
            }
        } else if (self -> baselineFregmentId == nowFregmentId - 1) {
            // load
            needReloadFregmentId = self -> baselineFregmentId;
        } else {
            
        }
        
        
//        [self doLoadDataWithFregmentId:nowFregmentId :^(NSData *data) {
//
//        } :^{
//
//        }];
//        if (baselineFregmentId - )
    }];
}

-(void) doLoadDataWithFregmentId:(int) fregmentId :(void (^)(NSData *data))successHandler :(void (^)(void))failedHander {
    NSLog(@"load fregment: %d", fregmentId);
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval nowTime = [date timeIntervalSince1970];
    LISEtc *etc = [LISEtc shareInstance];
    NSString *signedMd5Id = [[NSString stringWithFormat:@"%@_%d", etc.salt, fregmentId] MD5Digest];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@.mp3", etc.cdnDomain, self.radioInfo.baseUrl, signedMd5Id];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 6;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (nil != error) {
            NSLog(@"load with error: %d", fregmentId);
            failedHander();
            return;
//            if (1 == fregmentId - self -> doneFregmentId) {
//                NSTimer *timer = [NSTimer timerWithTimeInterval:2.0f repeats:NO block:^(NSTimer * _Nonnull timer) {
//                    [self loadMediaFregmentWith:distance];
//                }];
//                self.mediaTimer = timer;
//                [[NSRunLoop mainRunLoop] addTimer:self.mediaTimer forMode:NSDefaultRunLoopMode];
//            }
//            return;
        }
        if (self -> doneFregmentId >= fregmentId) {
            return;
        }
        successHandler(data);
        
        NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval loadDone = [date timeIntervalSince1970];
        NSLog(@"done: %d, time: %f", fregmentId, loadDone - nowTime);
        
    }];
    [task resume];
}

-(void) stop {
    [self.timer invalidate];
    self.timer = nil;
}

-(void) loadMuteData {
    NSString *muteFile = [[NSBundle mainBundle] pathForResource:@"mute" ofType:@"mp3"];
    NSData *muteData = [NSData dataWithContentsOfFile:muteFile];
    [self.data appendData:muteData];
}

@end
