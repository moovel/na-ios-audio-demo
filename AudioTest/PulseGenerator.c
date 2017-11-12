//
//  PulseGenerator.c
//  AudioTest
//
//  Created by Dan Weston on 11/11/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

#include <math.h>
#include <stdbool.h>

#include "PulseGenerator.h"

//    PulseGenerator(double sampleRate) {
//        sampleRate_ = sampleRate;
//        freq_ = 440.0;
//        amplitude_ = 0.25;
//        width_ = 0.5;
//        setWidthSweep(0.1,0.9,5.0);
//    }

SquareChannelInfo squareInfo;

bool isSweepingUp_ = false;
bool isSweeping_ = false;
float widthIterator_ = 0;
float width_;
float sweepScaler_;
float widthHigh_;
float widthLow_;

void setWidthSweepC(float widthLow, float widthHigh, float seconds, float width) {
    width_ = width;
    widthHigh_ = widthHigh;
    widthLow_ = widthLow;
    sweepScaler_ = fabs(widthHigh - widthLow) / (seconds * squareInfo.sampleRate);  // should this expression use () like that?
    isSweeping_ = true;
}

void handleSweep(){
    if(!isSweeping_) return;
    if(isSweepingUp_){
        width_ += sweepScaler_;
        if(width_ >= widthHigh_)
            isSweepingUp_ = false;
    }
    else{
        width_ -=  sweepScaler_;
        if(width_ <= widthLow_)
            isSweepingUp_ = true;
    }
}

bool isOn(){
    if(width_ == 1) {
        return true;
    }
    if(width_ == 0) {
        return false;
    }
    if(widthIterator_ < (squareInfo.sampleRate / squareInfo.frequency) * width_){
        widthIterator_ += 1;
        handleSweep();
        return true;
    }
    else{
        if(widthIterator_ >= squareInfo.sampleRate / squareInfo.frequency ){
            widthIterator_ = 0;
        }
        widthIterator_ += 1;
        handleSweep();
        return false;
    }
}

// this is the chewy center
void render(float *buffer, int32_t channelStride, int32_t numFrames, float amplitude){
    int sampleIndex = 0;
    for(int i = 0; i < numFrames; i++){
        if(isOn()) {
            buffer[sampleIndex] = (float) (1 * squareInfo.amplitude);
        } else {
            buffer[sampleIndex] = (float) (0 * squareInfo.amplitude);
        }
        sampleIndex += channelStride;
    }
}

/**
 This is what interfaces with iOS Audio system
 we delegate to internal guts in the render function
 */
OSStatus RenderSquareWave(
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
    SquareChannelInfo *channelInfo = (SquareChannelInfo *)inRefCon;
   
    assert(ioData->mNumberBuffers == numChannels);
    
    for (size_t chan = 0; chan < numChannels; chan++) {
        Float32 *buffer = (Float32 *)ioData->mBuffers[chan].mData;
        render(buffer,1,inNumberFrames, channelInfo[chan].amplitude);
    }
    
    return noErr;
}


 
    



    

    


