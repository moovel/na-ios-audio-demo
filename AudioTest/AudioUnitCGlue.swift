//
//  AudioUnitCGlue.swift
//  AudioTest
//
//  Created by Dan Weston on 11/11/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

import Foundation

// MARK: callbacks

// MARK: C AudioUnit callback wrappers
// this delegates to a C function, but we have this swift wrapper to make the Audio callback protocol happy
public func renderCallbackSinInC(inRefCon: UnsafeMutableRawPointer,
                                  ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                                  inTimeStamp: UnsafePointer<AudioTimeStamp>,
                                  inBusNumber: UInt32,
                                  inNumberFrames: UInt32,
                                  ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    return RenderSineWave(inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData)
}

// this delegates to a C function, but we have this swift wrapper to make the Audio callback protocol happy
public func renderCallbackSquareInC(inRefCon: UnsafeMutableRawPointer,
                                     ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                                     inTimeStamp: UnsafePointer<AudioTimeStamp>,
                                     inBusNumber: UInt32,
                                     inNumberFrames: UInt32,
                                     ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    return RenderSquareWave(inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData)
}

// this delegates to a C function, but we have this swift wrapper to make the Audio callback protocol happy
public func renderCallbackInputInC(inRefCon: UnsafeMutableRawPointer,
                                ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                                inTimeStamp: UnsafePointer<AudioTimeStamp>,
                                inBusNumber: UInt32,
                                inNumberFrames: UInt32,
                                ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    return recordingCallback(inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData)
}




