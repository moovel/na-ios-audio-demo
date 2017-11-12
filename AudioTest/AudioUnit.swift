//
//  AudioUnit.swift
//  AudioTest
//
//  Created by Dan Weston on 11/9/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

import Foundation
import AudioToolbox
import AudioUnit
import CoreAudio

enum WaveType {
    case squareInC,sinInSwift,sinInC,squareinSwift
}

class ToneGenerator {
    private var toneUnit: AudioUnit? = nil
    private var waveType: WaveType = .sinInSwift
    
    init(waveType: WaveType) {
        self.waveType = waveType
        setupAudioUnit(waveType: waveType)
    }
    
    deinit {
        stop()
    }
    
    func setupAudioUnit(waveType: WaveType) {
        
        // Configure the description of the output audio component we want to find:
        let componentSubtype: OSType
        #if os(OSX)
            componentSubtype = kAudioUnitSubType_DefaultOutput
        #else
            componentSubtype = kAudioUnitSubType_RemoteIO
        #endif
        var defaultOutputDescription = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                                                 componentSubType: componentSubtype,
                                                                 componentManufacturer: kAudioUnitManufacturer_Apple,
                                                                 componentFlags: 0,
                                                                 componentFlagsMask: 0)
        let defaultOutput = AudioComponentFindNext(nil, &defaultOutputDescription)
        
        var err: OSStatus
        
        // Create a new instance of it in the form of our audio unit:
        err = AudioComponentInstanceNew(defaultOutput!, &toneUnit)
        assert(err == noErr, "AudioComponentInstanceNew failed")
        
        // the default sine generator in swift needs minimal setup
        var renderer: AudioToolbox.AURenderCallback = renderCallbackSin
        var inputProcRef: UnsafeMutableRawPointer? = nil
        
        // the audio unit generators in C need a data structure to be filled up and passed along
        if waveType == .sinInC {
            sineInfo.sampleRate = sampleRate
            sineInfo.amplitude = amplitude
            sineInfo.frequency = frequency
            sineInfo.theta = 0
            inputProcRef = UnsafeMutableRawPointer(&sineInfo)
            renderer = renderCallbackSinInC
        } else if waveType == .squareInC {
            //renderer = renderCallbackSquare
            squareInfo.sampleRate = sampleRate
            squareInfo.amplitude = amplitude
            squareInfo.frequency = frequency
            setWidthSweepC(0.1,0.9,5.0,0.5)
            
            inputProcRef = UnsafeMutableRawPointer(&squareInfo)
            renderer = renderCallbackSquareInC
        } else if waveType == .squareinSwift {
            renderer = renderCallbackSquare
        }
        
        
        // Set the render callback as the input for our audio unit:
        var renderCallbackStruct = AURenderCallbackStruct(inputProc: renderer,
                                                          inputProcRefCon: inputProcRef)
        err = AudioUnitSetProperty(toneUnit!,
                                   kAudioUnitProperty_SetRenderCallback,
                                   kAudioUnitScope_Input,
                                   0,
                                   &renderCallbackStruct,
                                   UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        assert(err == noErr, "AudioUnitSetProperty SetRenderCallback failed")
        
        // Set the stream format for the audio unit. That is, the format of the data that our render callback will provide.
        var streamFormat = AudioStreamBasicDescription(mSampleRate: Float64(sampleRate),
                                                       mFormatID: kAudioFormatLinearPCM,
                                                       mFormatFlags: kAudioFormatFlagsNativeFloatPacked|kAudioFormatFlagIsNonInterleaved,
                                                       mBytesPerPacket: 4 /*four bytes per float*/,
                                                        mFramesPerPacket: 1,
                                                        mBytesPerFrame: 4,
                                                        mChannelsPerFrame: 1,
                                                        mBitsPerChannel: 4*8,
                                                        mReserved: 0)
        err = AudioUnitSetProperty(toneUnit!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   0,
                                   &streamFormat,
                                   UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        assert(err == noErr, "AudioUnitSetProperty StreamFormat failed")
        
    }
    
    func start() {
        var status: OSStatus
        // we only call setWidthSweep if we are using the square generator written in swift
        if self.waveType == .squareinSwift {
            setWidthSweep(widthL: 0.1, widthH: 0.9, seconds: 5.0)
        }

        status = AudioUnitInitialize(toneUnit!)
        status = AudioOutputUnitStart(toneUnit!)
        assert(status == noErr)
    }
    
    func stop() {
        AudioOutputUnitStop(toneUnit!)
        AudioUnitUninitialize(toneUnit!)
    }
    
}
// Fixed values used for sin wave and square wave
public let sampleRate: Float = 44100.0
public let amplitude: Float = 0.25
public let frequency: Float = 440.0

// MARK: Sine Wave - in swift
/// For Sine wave, theta is changed over time as each sample is provided.
private var theta: Float = 0.0

private func renderCallbackSin(inRefCon: UnsafeMutableRawPointer,
                               ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                               inTimeStamp: UnsafePointer<AudioTimeStamp>,
                               inBusNumber: UInt32,
                               inNumberFrames: UInt32,
                               ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    let abl = UnsafeMutableAudioBufferListPointer(ioData)
    let buffer = abl![0]
    let pointer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(buffer)
    for frame in 0..<inNumberFrames {
        let pointerIndex = pointer.startIndex + (Int(frame))
        pointer[pointerIndex] = sin(theta) * amplitude
        theta += 2.0 * Float(Double.pi) * frequency / Float(sampleRate)
    }
    
    return noErr
}

// MARK: Square Wave - in swift
// values that change
private var isSweepingUp = false
private var isSweeping = false
private var widthIterator: Float = 0.0
private var width: Float = 0.5
private var sweepScaler: Float = 0.0
private var widthHigh: Float = 0.0
private var widthLow: Float = 0.0

private func renderCallbackSquare(inRefCon: UnsafeMutableRawPointer,
                                  ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                                  inTimeStamp: UnsafePointer<AudioTimeStamp>,
                                  inBusNumber: UInt32,
                                  inNumberFrames: UInt32,
                                  ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    let abl = UnsafeMutableAudioBufferListPointer(ioData)
    let buffer = abl![0]
    let pointer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(buffer)
    var pointerIndex = 0
    for frame in 0..<inNumberFrames {
        pointerIndex = pointer.startIndex + Int(frame)
        if isOn() {
            pointer[pointerIndex] = 1 * amplitude
        } else {
            pointer[pointerIndex] = 0 * amplitude
        }
    }
    
    return noErr
}

// MARK: square wave helpers
private func setWidthSweep(widthL: Float, widthH: Float, seconds: Float){
    widthHigh = widthH
    widthLow = widthL
    sweepScaler = fabs(widthHigh - widthLow) / seconds * sampleRate
    isSweeping = true;
}

private func handleSweep() {
    if !isSweeping {
        return
    }
    
    if isSweepingUp {
        width += sweepScaler
        if(width >= widthHigh) {
            isSweepingUp = false
        }
    } else {
        width -=  sweepScaler
        if width <= widthLow {
           isSweepingUp = true
        }
    }
}

 private func isOn() -> Bool {
    if width == 1 {
        return true
    }
    if width == 0 {
        return false
    }
    if widthIterator < sampleRate / frequency * width {
        widthIterator += 1
        handleSweep()
        return true
    } else {
        if widthIterator >= sampleRate / frequency {
            widthIterator = 0
        }
        widthIterator += 1
        handleSweep()
        return false
    }
}


