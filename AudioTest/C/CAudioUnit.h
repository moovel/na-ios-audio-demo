//
//  CAudioUnit.h
//  AudioTest
//
//  Created by Dan Weston on 11/10/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

#ifndef CAudioUnit_h
#define CAudioUnit_h

#include <AudioToolbox/AudioToolbox.h>

OSStatus RenderSineWave(void *inRefCon,
                    AudioUnitRenderActionFlags   *ioActionFlags,
                    const AudioTimeStamp         *inTimeStamp,
                    UInt32                         inBusNumber,
                    UInt32                         inNumberFrames,
                    AudioBufferList             *ioData);

typedef struct {
    double sampleRate;
    double frequency;
    double amplitude;
    double theta;
} SineChannelInfo;

SineChannelInfo sineInfo;

#endif /* CAudioUnit_h */
