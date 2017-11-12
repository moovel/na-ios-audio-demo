//
//  PulseGenerator.h
//  AudioTest
//
//  Created by Dan Weston on 11/11/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

#ifndef PulseGenerator_h
#define PulseGenerator_h

#include <stdio.h>
#include <AudioToolbox/AudioToolbox.h>


OSStatus RenderSquareWave(void *inRefCon,
                    AudioUnitRenderActionFlags   *ioActionFlags,
                    const AudioTimeStamp         *inTimeStamp,
                    UInt32                         inBusNumber,
                    UInt32                         inNumberFrames,
                    AudioBufferList             *ioData);

typedef struct {
    float sampleRate;
    float frequency;
    float amplitude;
} SquareChannelInfo;

SquareChannelInfo squareInfo;

void setWidthSweepC(float widthLow, float widthHigh, float seconds, float width);

#endif /* PulseGenerator_h */
