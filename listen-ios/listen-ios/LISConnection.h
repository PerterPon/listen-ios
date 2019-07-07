//
//  LISConnection.h
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket.h>

NS_ASSUME_NONNULL_BEGIN

@interface LISConnection : NSObject <SRWebSocketDelegate>
    
    @property (nonatomic, strong, nullable) SRWebSocket *socket;
    @property (nonatomic, strong, nullable) NSTimer *heartBeat;
    @property (nonatomic, strong, nullable) NSString *currentChannelName;
    @property (nonatomic, strong, nullable) NSMutableArray *commandQueue;
    @property (nonatomic, strong, nullable) NSString *channelName;
    
    +(instancetype) shareInstance;

    -(void) initConnection;
    -(void) changeChannelName2:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
