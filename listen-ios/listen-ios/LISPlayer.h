//
//  LISPlayer.h
//  listen-ios
//
//  Created by PerterPon on 2019/7/7.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LISPlayer : NSObject
    
    @property (nonatomic, strong) NSString *baseUrl;
    @property (nonatomic, strong) NSString *name;
    
    +(instancetype) shareInstance;

    -(void) initPlayer;
    -(void) onFirstFregment:(NSString *)fregmentName;
    -(void) onMediaFregment:(NSString *)fregmentId;

@end

NS_ASSUME_NONNULL_END
