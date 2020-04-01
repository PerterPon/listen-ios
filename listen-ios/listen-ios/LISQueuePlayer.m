//
//  LISQueuePlayer.m
//  listen-ios
//
//  Created by PerterPon on 2019/8/4.
//  Copyright © 2019 PerterPon. All rights reserved.
//

#import "LISQueuePlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <NSString+MD5.h>
//#import "LISData.h"
//#import "LISRadioData.h"
//#import "LISQueueData.h"
#import "LISRadioDataNew.h"

#define NUM_BUFFERS 3
static UInt32 gBufferSizeBytes = 0x8000;//It muse be pow(2,x)

@interface LISQueuePlayer() {
    AudioFileID audioFile;
    AudioStreamBasicDescription dataFormat;
    AudioQueueRef queue;
    SInt64 packetIndex;
    UInt32 numPacketsToRead;
    UInt32 bufferByteSize;
    AudioStreamPacketDescription *packetDesc;
    AudioQueueBufferRef buffers[NUM_BUFFERS];
    UInt32 maxPacketSize;
    AudioQueueBufferRef latestBuffer;
    
    BOOL pausing;
}

@end

@implementation LISQueuePlayer

static OSStatus readProc(
                         void   *inClientData,
                         SInt64 position,
                         UInt32 requestCount,
                         void   *buffer,
                         UInt32 *actualCount
                         ) {
    LISRadioDataNew *lisData = [LISRadioDataNew shareInstance];
    
    size_t bytes_to_read = requestCount;
    
    if (requestCount > lisData.data.length) {
        bytes_to_read = lisData.data.length;
    }
    
    *actualCount = (UInt32)bytes_to_read;
    
    NSRange range = NSMakeRange(position, bytes_to_read);
    [lisData.data getBytes:buffer range:range];
//    NSLog(@"read data length: %d, data remain lengeh: %lu", requestCount, (unsigned long)lisData.data.length);
    return noErr;
}

static SInt64 getSizeProc(void *inClientData) {
    LISRadioDataNew *lisData = [LISRadioDataNew shareInstance];
    size_t dataSize = lisData.data.length;
    return dataSize;
}

static void BufferCallback(void *inUserData,AudioQueueRef inAQ,
                           AudioQueueBufferRef buffer){
//    NSLog(@"BufferCallback");
    LISQueuePlayer* player=(__bridge LISQueuePlayer* )inUserData;
    [player readPacketTo:buffer];
}

- (void) play {
    if (NO == pausing) {
        AudioQueueStart(queue, nil);
        self.playying = YES;
    }
}

- (void) pause {
    AudioQueuePause(queue);
    self.playying = NO;
    pausing = YES;
    [self emptyBuffers];
}

- (void) resume {
    [self refillBuffes];
    pausing = NO;
    [self play];
}

- (void) emptyBuffers {
    if (nil == latestBuffer) {
        NSLog(@"没有需要清理的buffer");
        return;
    }
    
    AudioQueueBufferRef buffer = latestBuffer;
    while (true) {
        if (0 != buffer -> mAudioDataByteSize) {
            break;
        }
        buffer -> mAudioDataByteSize = 0;
    }
}

- (void) refillBuffes {
    if (nil == latestBuffer) {
        NSLog(@"没有需要填充的buffer");
        return;
    }
    
    AudioQueueBufferRef buffer = latestBuffer;
    while (true) {
        if (0 != buffer -> mAudioDataByteSize) {
            break;
        }
        NSLog(@"refillBuffes");
        int res = [self readPacketTo:buffer];
        if (2 == res) {
            break;
        }
        buffer = buffer -> mUserData;
    }
}

- (void) initQueue {
    UInt32 size;
    char *cookie;
    int i;
    OSStatus status;
    
    pausing = NO;
    
    status = AudioFileOpenWithCallbacks((__bridge void * _Nonnull)(self), readProc, NULL, getSizeProc, NULL, 0, &audioFile);
    if (noErr != status) {
        NSLog(@"open file with error");
        NSTimer *timer = [NSTimer timerWithTimeInterval:3.0f repeats:NO block:^(NSTimer * _Nonnull timer) {
            [self initQueue];
        }];

        self.timer = timer;
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        return;
    }
    
    size = sizeof(dataFormat);
    AudioFileGetProperty(audioFile, kAudioFilePropertyDataFormat, &size, &dataFormat);
    
    AudioQueueNewOutput(&dataFormat, BufferCallback, (__bridge void * _Nullable)(self), nil, nil, 0, &queue);
    
    if (dataFormat.mBytesPerPacket == 0 || dataFormat.mFramesPerPacket == 0) {
        size = sizeof(maxPacketSize);
        AudioFileGetProperty(audioFile, kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize);
        if (maxPacketSize > gBufferSizeBytes) {
            maxPacketSize = gBufferSizeBytes;
        }
        
        numPacketsToRead = gBufferSizeBytes / maxPacketSize;
        packetDesc = malloc(sizeof(AudioStreamPacketDescription) *numPacketsToRead);
    } else {
        numPacketsToRead = gBufferSizeBytes / dataFormat.mBytesPerPacket;
        packetDesc = nil;
    }
    
    AudioFileGetProperty(audioFile, kAudioFilePropertyMagicCookieData, &size, nil);
    if (size > 0) {
        cookie = malloc(sizeof(char)* size);
        AudioFileGetProperty(audioFile, kAudioFilePropertyMagicCookieData, &size, cookie);
        AudioQueueSetProperty(queue, kAudioQueueProperty_MagicCookie, cookie, size);
    }
    
    for (i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueAllocateBuffer(queue, gBufferSizeBytes, &buffers[i]);
        int readResult = [self readPacketTo:buffers[i]];
        if (0 < i) {
            buffers[i - 1] -> mUserData = buffers[i];
        }
        if (i == NUM_BUFFERS - 1) {
            buffers[i] -> mUserData = buffers[0];
        }
        if (1 == readResult) {
            break;
        }
    }
    
    latestBuffer = nil;
    
    Float32 gain = 2;
    AudioQueueSetParameter(queue, kAudioQueueParam_Volume, gain);
}

- (int) readPacketTo:(AudioQueueBufferRef) buffer {
    
    UInt32 numBytes, numPackets;
    
    numPackets = numPacketsToRead;
    AudioFileReadPackets(audioFile, NO, &numBytes, packetDesc, 0, &numPackets, buffer->mAudioData);

    if (0 == numBytes) {
        buffer -> mAudioDataByteSize = 0;
        if (nil == latestBuffer) {
            latestBuffer = buffer;
        }
        BOOL result = [self checkAllBufferStatus];
        if (NO == result) {
            return 2;
        } else {
            return 1;
        }
    }

    if (numPackets > 0) {
        buffer -> mAudioDataByteSize = numBytes;
        AudioQueueEnqueueBuffer(queue, buffer, (packetDesc ? numPackets : 0), packetDesc);
        LISRadioDataNew *lisData = [LISRadioDataNew shareInstance];
        [lisData.data replaceBytesInRange:NSMakeRange(0, numBytes) withBytes:NULL length:0];
//        NSLog(@"data remain lengeh: %lu", (unsigned long)lisData.data.length);
        return 0;
    } else {
        return 1;
    }
}

- (BOOL) checkAllBufferStatus {
    int avaliableBuffers = 0;
    for (int i = 0; i < NUM_BUFFERS; i++) {
        if (0 != buffers[i] -> mAudioDataByteSize) {
            avaliableBuffers += 1;
            break;
        }
    }
    if (0 == avaliableBuffers) {
        NSLog(@"暂停");
        self.playying = NO;
        AudioQueuePause(queue);
        return NO;
    } else {
        return YES;
    }
}

@end
