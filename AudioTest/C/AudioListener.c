//
//  AudioListener.c
//  AudioTest
//
//  Created by Dan Weston on 11/20/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

#include "AudioListener.h"

ListenerInfo listenerInfo;
TPCircularBuffer circularBuffer;


OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    // if we don't have a circular buffer yet, initialize it now
    int bufferSize = listenerInfo.sampleRate*4*5;     // 5 seconds of buffer space
    
    if(circularBuffer.buffer == NULL) {
        TPCircularBufferInit(&circularBuffer,bufferSize);
        //printf("initializing circular buffer");
    }

    // a variable where we check the status
    OSStatus status;
    
    /**
     This is the reference to the object who owns the callback.
     */
    ListenerInfo *info = (ListenerInfo*) inRefCon;
    AudioUnit audioUnit = info->audioUnit;
    //AudioBufferList * bufferList = TPCircularBufferPrepareEmptyAudioBufferList(&circularBuffer, 1, inNumberFrames * sizeof(float), inTimeStamp);
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mNumberChannels = 1;
    bufferList.mBuffers[0].mData = NULL;
    bufferList.mBuffers[0].mDataByteSize = inNumberFrames * sizeof(float);

    
    // render input and check for error
    status = AudioUnitRender(audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    
    // stick the new input into the circular buffer, some other part of the app will pick it up there from another thread
    if(status == noErr) {
        float first = ((float *)bufferList.mBuffers[0].mData)[0];
        //printf("first float in C: %f\n", first);
        //TPCircularBufferProduceAudioBufferList(&circularBuffer, inTimeStamp);
        TPCircularBufferProduceBytes(&circularBuffer,bufferList.mBuffers[0].mData,bufferList.mBuffers[0].mDataByteSize);
    }
    return noErr;
}
