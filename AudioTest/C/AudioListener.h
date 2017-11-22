//
//  AudioListener.h
//  AudioTest
//
//  Created by Dan Weston on 11/20/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

#ifndef AudioListener_h
#define AudioListener_h

#include <AudioToolbox/AudioToolbox.h>
#include "../../Pods/TPCircularBuffer/TPCircularBuffer+AudioBufferList.h"

OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData);

typedef struct {
    AudioUnit audioUnit;
    double       sampleRate;
} ListenerInfo;

ListenerInfo listenerInfo;
TPCircularBuffer circularBuffer;

#endif /* AudioListener_h */
