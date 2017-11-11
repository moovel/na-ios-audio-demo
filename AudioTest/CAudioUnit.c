//
//  CAudioUnit.c
//  AudioTest
//
//  Created by Dan Weston on 11/10/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

#include "CAudioUnit.h"

ChannelInfo info;

OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags   *ioActionFlags,
                    const AudioTimeStamp         *inTimeStamp,
                    UInt32                         inBusNumber,
                    UInt32                         inNumberFrames,
                    AudioBufferList             *ioData)

{
    // hard code number of channels to 1
    int numChannels = 1;
    
    // Get the tone parameters out of the object
    ChannelInfo *channelInfo = (ChannelInfo *)inRefCon;
   assert(ioData->mNumberBuffers == numChannels);
    
   for (size_t chan = 0; chan < numChannels; chan++) {
        double theta = channelInfo[chan].theta;
        double amplitude = channelInfo[chan].amplitude;
        double theta_increment = 2.0 * M_PI * channelInfo[chan].frequency / channelInfo[chan].sampleRate;
        
        Float32 *buffer = (Float32 *)ioData->mBuffers[chan].mData;
        // Generate the samples
        for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
            buffer[frame] = sin(theta) * amplitude;
            
            theta += theta_increment;
            // Basically do modulo
            if (theta > 2.0 * M_PI) {
                theta -= 2.0 * M_PI;
            }
        }
        
        // Store the theta back in the view controller
        channelInfo[chan].theta = theta;
    }
    
    return noErr;
}
