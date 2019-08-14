//
//  LISData.m
//  listen-ios
//
//  Created by PerterPon on 2019/7/8.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "LISData.h"
#import <AFNetworking.h>
#import "LISEtc.h"

dispatch_queue_t downloadQueue;

@implementation LISData

static LISData *data;

+(instancetype) shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        data = [[self alloc] init];
        downloadQueue = dispatch_queue_create("pon.listen.data", DISPATCH_QUEUE_SERIAL);
    });
    
    return data;
}

-(void) initData {
    self.data = [[NSMutableData alloc] init];
    self.mediaFregmentCount = 0;
    self.requestQueue = [[NSMutableArray alloc] init];
    self.loading = NO;
    self.firstFregment = nil;
}

-(void) clearData {
    self.data = [[NSMutableData alloc] init];
}

-(void) onFirstFregment: (NSDictionary *)firstFregment{
    NSLog(@"did receive first fregment");
    struct FirstFregment firstFregmentData;
    firstFregmentData.codecs = firstFregment[@"codecs"];
    firstFregmentData.duration = firstFregment[@"duration"];
    firstFregmentData.timescale = firstFregment[@"timescale"];
    firstFregmentData.mimeType = firstFregment[@"mimeType"];
    firstFregmentData.sampleRate = firstFregment[@"sampleRate"];
    firstFregmentData.fileName =firstFregment[@"fileName"];
    self.firstFregmentData = firstFregmentData;

    NSString *urlString = [NSString stringWithFormat:@"%@/%@", self.baseUrl, firstFregmentData.fileName];
    [self.requestQueue addObject:urlString];
    [self requestFile];
}

-(void) onMediaFregment:(NSString *)fregmentId {
//    NSLog(@"did receive media fregment");
    NSString *urlString = [NSString stringWithFormat:@"%@/%@.mp3", self.baseUrl, fregmentId];
    [self.requestQueue addObject:urlString];
    [self requestFile];
}

-(void) requestFile {
    if (YES == self.loading) {
        return;
    }
    [self doRequest:0];
}

-(void) doRequest: (int)failedTimes {
    if (0 == self.requestQueue.count) {
        return;
    }
    
    if (2 <= failedTimes) {
        NSLog(@"failed too much times ignore");
        [self.requestQueue removeObjectAtIndex:0];
        failedTimes = 0;
        return;
    }

    NSString *urlString = [self.requestQueue objectAtIndex:0];
    NSURLSession *session = [NSURLSession sharedSession];
    
    LISEtc *etc = [LISEtc shareInstance];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", etc.cdnDomain, urlString]];
//    NSLog(@"request with url: %@", url);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    self.loading = YES;
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSTimeInterval before = [date timeIntervalSince1970];
    NSURLSessionDataTask *dataTask = [session
                                      dataTaskWithRequest: request
                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                          self.loading = NO;
                                          if (error) {
                                              NSLog(@"download with error");
                                              [self doRequest:failedTimes + 1];
                                              return;
                                          }
                                          NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
                                          NSTimeInterval after = [date timeIntervalSince1970];
                                          NSLog(@"下载数据包花费时间：%f", after - before);
                                          [self.requestQueue removeObjectAtIndex:0];
                                          if (YES == [urlString containsString:@".dash"]) {
                                              self.firstFregment = data;
                                          } else {
                                              [self.data appendData:data];
                                          }
                                          [self doRequest:0];
                                          self.mediaFregmentCount++;
                                          [self triggerDelegateWith:urlString andData:data];
                                      }];
    [dataTask resume];
}

-(void) triggerDelegateWith: (NSString *)urlString andData: (NSData *)data {
    if (self.delegate) {
        if (YES == [urlString containsString:@".dash"]) {
            [self.delegate dataDidReceiveFirstFregment];
        } else {
            [self.delegate
                dataDidReceiveMediaFregmentWithNumber:self.mediaFregmentCount];
        }
    }
}

-(void) downloadFile:(NSString *)urlString {
    NSURLSession *session = [NSURLSession sharedSession];
    
    LISEtc *etc = [LISEtc shareInstance];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", etc.cdnDomain, urlString]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *dataTask = [session
                                      dataTaskWithRequest: request
                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                          if (error) {
                                              NSLog(@"download with error");
                                              return;
                                          }
                                          [self.data appendData:data];
                                      }];
    [dataTask resume];
    
}

@end
