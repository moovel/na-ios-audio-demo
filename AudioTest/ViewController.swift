//
//  ViewController.swift
//  AudioTest
//
//  Created by Dan Weston on 11/9/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private var toneGenerator = ToneGenerator(waveType: .squareInC)
    private var playing: Bool = false
    
    private var listener = AudioListener()
    var displayLink:CADisplayLink?
    
    @IBOutlet weak var oscilloscopeView: OscilloscopeView!
    @IBOutlet weak var playButton: UIButton!
   
    @IBAction func playTapped(_ sender: Any) {
        if playing {
            displayLink!.invalidate()
            displayLink = nil;
            
            playing = false
            toneGenerator.stop()
            listener.stop()
            playButton.setTitle("Play", for: .normal)
        } else {
            playing = true
            toneGenerator.start()
            listener.start()
            playButton.setTitle("Stop", for: .normal)
            
            if displayLink == nil {
                displayLink = CADisplayLink.init(target: self, selector: #selector(updateData))
            }
            displayLink!.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
        }
    }
    
    // this function gets called on the VSync interrupt of the display
    // read the circular buffer
    @objc func updateData(displayLink:CADisplayLink) {
        var availableBytes: Int32 = 0
        if circularBuffer.buffer != nil && circularBuffer.head != circularBuffer.tail {
            let buffer: UnsafeMutableRawPointer = TPCircularBufferTail(&circularBuffer, &availableBytes)
            //print("got an interrupt, \(availableBytes) available, \thead/tail: \(circularBuffer.head)/\(circularBuffer.tail)")
            
            // do something with the bytes in buffer
            // https://stackoverflow.com/questions/38983277/how-to-get-bytes-out-of-an-unsafemutablerawpointer
            buffer.bindMemory(to: Float.self, capacity: Int(availableBytes))
            let floatbufptr = UnsafeBufferPointer(start: buffer.assumingMemoryBound(to: Float.self), count: Int(availableBytes / 4))
            let floatarray = Array<Float>(floatbufptr)
            //print("first float in swift: \(floatarray[0])")
            // now release the bytes we just read
            oscilloscopeView.dataBuffer = floatarray

            // do the computation in a non-main thread
            DispatchQueue.global(qos: .background).async {
                self.oscilloscopeView.convertToPoints()
                DispatchQueue.main.async {
                    self.oscilloscopeView.setNeedsDisplay()
                }
            }
            TPCircularBufferConsume(&circularBuffer, availableBytes)
        } else {
           // print("skipping a beat")
        }
    }
        
    @IBAction func resetButtonTap(_ sender: Any) {
        frequency = 440.0
        frequencyLabel.text = String(format: "%.2f hz", frequency)
        frequencySlider.value = Float(frequency)
        self.waveSelectionChanged(self)
    }
    
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var waveSelector: UISegmentedControl!
    @IBAction func waveSelectionChanged(_ sender: Any) {
        let wasPlaying = playing
        if wasPlaying {
            // stop everything while we switch
            self.playTapped(self)
        }
        
        let index = waveSelector.selectedSegmentIndex
        switch index {
        case 0:
            toneGenerator = ToneGenerator(waveType: .squareInC)
        case 1:
            toneGenerator = ToneGenerator(waveType: .sinInSwift)
        case 2:
            toneGenerator = ToneGenerator(waveType: .sinInC)
        default:
            assert(false, "unexpected segment index")
        }
        
        // now we have a new toneGenerator, resume play if we were playing before
        if wasPlaying {
            self.playTapped(self)
        }
    }
    @IBOutlet weak var frequencySlider: UISlider!
    
    @IBAction func frequencyChanged(_ sender: Any) {
        let newValue = frequencySlider.value
        frequency = Double(newValue)
        self.waveSelectionChanged(self)
        frequencyLabel.text = String(format: "%.2f hz", frequency)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // get the wave type set up right off the bat
        self.waveSelectionChanged(self)
        frequencyLabel.text = String(format: "%.2f hz", frequency)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

