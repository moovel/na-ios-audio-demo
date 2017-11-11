//
//  ViewController.swift
//  AudioTest
//
//  Created by Dan Weston on 11/9/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private var toneGenerator = ToneGenerator(waveType: .square)
    private var playing: Bool = false
    
    @IBOutlet weak var playButton: UIButton!
   
    @IBAction func playTapped(_ sender: Any) {
        if playing {
            playing = false
            toneGenerator.stop()
            playButton.setTitle("Play", for: .normal)
        } else {
            playing = true
            toneGenerator.start()
            playButton.setTitle("Stop", for: .normal)

        }
    }
    
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
            toneGenerator = ToneGenerator(waveType: .square)
        case 1:
            toneGenerator = ToneGenerator(waveType: .sin)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // get the wave type set up right off the bat
        self.waveSelectionChanged(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

