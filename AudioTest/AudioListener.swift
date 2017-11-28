//
//  ToneListener.swift
//  AudioTest
//
//  Created by Dan Weston on 11/15/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

import Foundation
import AudioToolbox
import AudioUnit
import CoreAudio
import AVFoundation

// https://gist.github.com/hotpaw2/ba815fc23b5d642705f2b1dedfaf0107

class AudioListener {
    public var listenerUnit: AudioUnit? = nil
    private let inputBus: UInt32    =  1
    
    var micPermission   =  false
    var sessionActive   =  false
    var isRecording     =  false
    
    var sampleRate : Double = 44100.0    // default audio sample rate
    
    var audioLevel : Float  = 0.0
    
    private var hwSRate = 48000.0   // guess of device hardware sample rate
    private var micPermissionDispatchToken = 0
    private var interrupted = false     // for restart from audio interruption notification

    init() {
        setupAudioUnit()
    }
    
    deinit {
        stop()
    }
    
    func setupAudioUnit() {
        // setup the circular buffer
        //_TPCircularBufferInit(UnsafeMutablePointer(&circBuffer), circBuffSize, sizeof(circBuffer))
        
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
        err = AudioComponentInstanceNew(defaultOutput!, &listenerUnit)
        assert(err == noErr, "AudioComponentInstanceNew failed")
        
        var renderer: AudioToolbox.AURenderCallback!
        var inputProcRef: UnsafeMutableRawPointer?
        
        let useSwiftFunc = false
        
        if useSwiftFunc {
            renderer = renderCallbackInput
            inputProcRef = UnsafeMutableRawPointer(listenerUnit)
            
        } else {
            renderer  = renderCallbackInputInC
            listenerInfo.audioUnit = listenerUnit
            listenerInfo.sampleRate = sampleRate
            
            inputProcRef = UnsafeMutableRawPointer(&listenerInfo)
            
        }
        
        // Set the render callback as the input for our audio unit:
        var renderCallbackStruct = AURenderCallbackStruct(inputProc: renderer,
                                                          inputProcRefCon: inputProcRef)

        
        
        var one_ui32: UInt32 = 1
        
        err = AudioUnitSetProperty(listenerUnit!,
                                     AudioUnitPropertyID(kAudioOutputUnitProperty_SetInputCallback),
                                     AudioUnitScope(kAudioUnitScope_Global),
                                     inputBus,
                                     &renderCallbackStruct,
                                     UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        
        err = AudioUnitSetProperty(listenerUnit!,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Input,
                                     inputBus,
                                     &one_ui32,
                                     UInt32(MemoryLayout<UInt32>.size))
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
        err = AudioUnitSetProperty(listenerUnit!,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Output,
                                   inputBus,
                                   &streamFormat,
                                   UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        assert(err == noErr, "AudioUnitSetProperty StreamFormat failed")
        
        err = AudioUnitSetProperty(listenerUnit!,
                                     AudioUnitPropertyID(kAudioUnitProperty_ShouldAllocateBuffer),
                                     AudioUnitScope(kAudioUnitScope_Output),
                                     inputBus,
                                     &one_ui32,
                                     UInt32(MemoryLayout<UInt32>.size))
        
    }
    
    func stopAudioSession() {
        if (sessionActive == true) {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(false)
                sessionActive = false
            } catch {
                
            }
        }
            
    }
    func startAudioSession() {
        if (sessionActive == false) {
            // set and activate Audio Session
            do {
                
                let audioSession = AVAudioSession.sharedInstance()
                
                if (micPermission == false) {
                    if (micPermissionDispatchToken == 0) {
                        micPermissionDispatchToken = 1
                        audioSession.requestRecordPermission({(granted: Bool)-> Void in
                            if granted {
                                self.micPermission = true
                                return
                                // check for this flag and call from UI loop if needed
                            } else {
                                //gTmp0 += 1
                                // dispatch in main/UI thread an alert
                                //   informing that mic permission is not switched on
                            }
                        })
                    }
                }
                if micPermission == false { return }
                
                try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                // choose 44100 or 48000 based on hardware rate
                // sampleRate = 44100.0
                var preferredIOBufferDuration = 0.0058      // 5.8 milliseconds = 256 samples
                hwSRate = audioSession.sampleRate           // get native hardware rate
                if hwSRate == 48000.0 {
                    sampleRate = 48000.0
                    listenerInfo.sampleRate = sampleRate
                }
                // set session to hardware rate
                if hwSRate == 48000.0 { preferredIOBufferDuration = 0.0053 }
                let desiredSampleRate = sampleRate
                
                
                try audioSession.setPreferredSampleRate(desiredSampleRate)
                try audioSession.setPreferredIOBufferDuration(preferredIOBufferDuration)
                
//                NotificationCenter.default.addObserver(
//                    forName: NSNotification.Name.AVAudioSessionInterruption,
//                    object: nil,
//                    queue: nil,
//                    using: myAudioSessionInterruptionHandler )
//
                try audioSession.setActive(true)
                sessionActive = true
            } catch /* let error as NSError */ {
                // handle error here
            }
        }
    }
    
    func start() {
        var status: OSStatus
        startAudioSession()

        status = AudioUnitInitialize(listenerUnit!)
        status = AudioOutputUnitStart(listenerUnit!)
        assert(status == noErr)
    }
    
    func stop() {
        stopAudioSession()
        
        AudioOutputUnitStop(listenerUnit!)
        AudioUnitUninitialize(listenerUnit!)
    }
}


//var circBuffer: TPCircularBuffer = TPCircularBuffer()
let circBuffSize: Int32 = 32768        // lock-free circular fifo/buffer size
var circBuffer   = [Float](repeating: 0, count: 32768)  // for incoming samples
var circInIdx  : Int =  0

public func renderCallbackInput(inRefCon: UnsafeMutableRawPointer,
                                ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                                inTimeStamp: UnsafePointer<AudioTimeStamp>,
                                inBusNumber: UInt32,
                                inNumberFrames: UInt32,
                                ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    //print("renderCallbackInput called, numberFrames: \(inNumberFrames)")
    let listenerAudioUnit = unsafeBitCast(inRefCon, to: AudioUnit.self)
    
    // set mData to nil, AudioUnitRender() should be allocating buffers
    let buffsize = inNumberFrames * 4
    
    var bufferList = AudioBufferList(
        mNumberBuffers: 1,
        mBuffers: AudioBuffer(
            mNumberChannels: UInt32(1),
            mDataByteSize: buffsize,
            mData: nil ))   // malloc(Int(buffsize)
    var err: OSStatus
    
    err = AudioUnitRender(listenerAudioUnit,
                          ioActionFlags,
                          inTimeStamp,
                          inBusNumber,
                          inNumberFrames,
                          &bufferList)
    
    // process here...
    let count = Int(inNumberFrames)
    
    let bufferPointer = UnsafeMutableRawPointer(bufferList.mBuffers.mData)
    if let bptr = bufferPointer {
        let dataArray = bptr.assumingMemoryBound(to: Float.self)
        var j = circInIdx
        let m = circBuffSize
        // copy sample
        // into circular buffer
        for i in 0..<count {
            let x = Float(dataArray[i])
            circBuffer[j ] = x
            j += 1 ; if j >= m
            {
                j = 0
            }
        }
        circInIdx = j
    }
    
    return err
}

