//
//  LISConnection.m
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "LISConnection.h"
#import "LISEtc.h"
#import <NSString+MD5.h>
#import "LISPlayer.h"

@implementation LISConnection
    
    static LISConnection *connection = nil;
    
    +(instancetype) shareInstance; {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            connection = [[self alloc] init];
            connection.commandQueue = [[NSMutableArray alloc] init];
        });
        
        return connection;
    }
    
    -(void) initConnection {
        [self close];
        LISEtc *etc = [LISEtc shareInstance];
        NSString *urlString = [NSString stringWithFormat:@"%@:%d", etc.domain, etc.port];
        NSURL *url = [NSURL URLWithString:urlString];
        NSLog(@"%@", url);
        NSURLRequest *request = [NSURLRequest requestWithURL:url];

        self.socket = [[SRWebSocket alloc] initWithURLRequest:request];
        self.socket.delegate = self;
        [self.socket open];
    }
    
    -(void) changeChannelName2:(NSString *)name {
        self.channelName = name;
        
        // only if socket is fine
        if (self.socket && 1 == self.socket.readyState) {
            [self register2Listen];
        }
    }
    
    -(void) close {
        self.socket.delegate = nil;

        if (self.socket) {
            [self.socket close];
        }
        self.socket = nil;
    }
    
    -(void) register2Listen {
        NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval time = [now timeIntervalSince1970] * 1000;
        NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
        NSString *salt = [LISEtc shareInstance].salt;
        NSString *targetString = [NSString stringWithFormat:@"%@%@", salt, timeString];
        NSString *sign = [targetString MD5Digest];
        NSDictionary *registerDic = @{
                                       @"event": @"register",
                                       @"data": @{
                                               @"timestamp": [NSNumber numberWithDouble:[timeString doubleValue]],
                                               @"sign": sign,
                                               @"name": self.channelName
                                               }
                                       };
        NSError *error;
        NSData *registerData = [NSJSONSerialization
                                dataWithJSONObject:registerDic
                                options:NSJSONWritingPrettyPrinted
                                error:&error];
        if (error) {
            NSLog(@"transfrom register data with error");
            return;
        }
        NSString *registerString = [[NSString alloc]
                                    initWithData:registerData
                                    encoding:NSUTF8StringEncoding];
        [self send: registerString];
    }
    
    -(void) ping {
        self.heartBeat = [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self close];
                [self reconnection];
            });
        }];
        NSDictionary *pingDic = @{
                                   @"event": @"ping"
                                   };
        NSError *error;
        NSData *pingData = [NSJSONSerialization
                                dataWithJSONObject:pingDic
                                options:NSJSONWritingPrettyPrinted
                                error:&error];
        if (error) {
            NSLog(@"transfrom ping data with error");
            return;
        }
        
        NSString *pingString = [[NSString alloc] initWithData:pingData encoding:NSUTF8StringEncoding];
        [self send: pingString];
    }
    
    -(void) pong {
        [self stopHeartBeat];
        [NSTimer scheduledTimerWithTimeInterval:20 repeats:NO block:^(NSTimer * _Nonnull timer) {
            [self ping];
        }];
    }
    
    -(void) stopHeartBeat {
        if (YES == self.heartBeat.isValid) {
            [self.heartBeat invalidate];
        }
        self.heartBeat = nil;
    }
    
    -(void) reconnection {
        [self stopHeartBeat];
        NSLog(@"restart connection after 8's later...");
        [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer * _Nonnull timer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self initConnection];
            });
        }];
    }
    
    -(void) send:(id)data {
        if(1 == self.socket.readyState) {
            [self.socket send: data];
        } else {
            [self.commandQueue addObject:data];
        }
    }
    
    #pragma mark - socket delegate
    
    -(void) webSocketDidOpen:(SRWebSocket *)webSocket {
        [self register2Listen];
        if(0 < [self.commandQueue count]) {
            for (int i = 0; i < [self.commandQueue count]; i++){
                id data = self.commandQueue[i];
                [webSocket send:data];
            }
            [self.commandQueue removeAllObjects];
        }
        [self ping];
    }
    
    -(void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
        NSError *error;
        NSData *jsonData = [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *data = [NSJSONSerialization
                              JSONObjectWithData:jsonData
                              options:NSJSONReadingMutableContainers
                              error:&error];
        if (error) {
            NSLog(@"parse receive message with error: %@", error);
        }
        
        NSString *eventName = data[@"event"];
        LISPlayer *player = [LISPlayer shareInstance];

        if([@"register" isEqualToString:eventName]) {
            NSDictionary *eventData = data[@"data"];
            NSString *firstFregment = eventData[@"firstFregment"];
            NSString *baseUrl = eventData[@"baseUrl"];
            NSNumber *latestFregment = eventData[@"latestFregment"];
            player.baseUrl = baseUrl;
            [player onFirstFregment:firstFregment];
            [player onMediaFregment:[latestFregment stringValue]];
        } else if ([@"pong" isEqualToString:eventName]) {
            [self pong];
        } else if ([@"mediaFregment" isEqualToString:eventName]) {
            NSNumber *fregmentId = data[@"data"];
            [player onMediaFregment:[fregmentId stringValue]];
        }
    }
    
    -(void) webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
        NSLog(@"ws error domain: [%@], code: [%ld]", error.domain, error.code);
        [self reconnection];
    }
    
    -(void) webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
        NSLog(@"ws close reason: [%@], code: [%ld]", reason, code);
        [self reconnection];
    }
    
@end
