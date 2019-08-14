//
//  ListenPlayer.h
//  listen-ios
//
//  Created by PerterPon on 2019/8/14.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ListenPlayer : NSObject

@property (nonatomic) BOOL playying;

- (void) initPlayer: (NSData *)headFile;

- (void) play;

- (void) pause;

- (void) stop;

- (void) addData: (NSData *)data;

@end

NS_ASSUME_NONNULL_END
