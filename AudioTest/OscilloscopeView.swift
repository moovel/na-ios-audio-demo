//
//  OcciliscopeView.swift
//  AudioTest
//
//  Created by Dan Weston on 11/26/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class OscilloscopeView : UIView {
 
    public var dataBuffer: Array<Float>? = nil
    public var amplitudeCorrection = Float(1000.0)
    var pointArray = [CGPoint](repeating: CGPoint(), count: 4096)
    
    override func draw(_ rect: CGRect) {
        //print("draw in rect, length: \(dataBuffer?.count ?? 0)")
        guard let inData = dataBuffer else {return}
        
        let fwidth = Float(rect.width)
        let fheight = Float(rect.height)
        let fcount = Float(inData.count)
        // convert array of floats to array of CGPoint
        for (index, element) in inData.enumerated() {
            // add some amplitude
            let ampedUp = element * amplitudeCorrection
           // first add the offset to put 0 at the midpoint, vertically, in the window
           let y = ampedUp + (fheight/2.0)
           // now figure the x coord
            let x = Float(index) * (fwidth/fcount)
            pointArray[index] = CGPoint(x: Double(x), y: Double(y))
        }
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(UIColor.black.cgColor)
            for (index, element) in pointArray.enumerated() {
                if index == 0 {
                    context.move(to: element)
                }
                if index >= inData.count {
                    break
                    
                }
                context.addLine(to: element)
            }
            context.drawPath(using: .stroke)
 
        }
    }
    
    /*
    -(void)drawInContext:(CGContextRef)ctx {
    CGContextSetShouldAntialias(ctx, false);
    
    // Render ring buffer as path
    CGContextSetLineWidth(ctx, 2);
    CGContextSetStrokeColorWithColor(ctx, [_lineColor CGColor]);
    
    int frames = kBufferLength-1;
    int tail = (_buffer_head+1) % kBufferLength;
    SAMPLETYPE x = 0;
    SAMPLETYPE xIncrement = (self.bounds.size.width / (float)(frames-1)) * (float)(kSkipFrames+1);
    SAMPLETYPE multiplier = self.bounds.size.height / 2.0;
    
    // Generate samples
    SAMPLETYPE *scratchPtr = (SAMPLETYPE*)_scratchBuffer;
    while ( frames > 0 ) {
    int framesToRender = MIN(frames, kBufferLength - tail);
    int samplesToRender = framesToRender / kSkipFrames;
    
    VRAMP(&x, &xIncrement, (SAMPLETYPE*)scratchPtr, 2, samplesToRender);
    VSMUL(&_buffer[tail], kSkipFrames, &multiplier, ((SAMPLETYPE*)scratchPtr)+1, 2, samplesToRender);
    
    scratchPtr += 2 * samplesToRender;
    x += (samplesToRender-1)*xIncrement;
    tail += framesToRender;
    if ( tail == kBufferLength ) tail = 0;
    frames -= framesToRender;
    }
    
    int sampleCount = (kBufferLength-1) / kSkipFrames;
    
    // Apply an envelope
    SAMPLETYPE start = 0.0;
    int envelopeLength = sampleCount / 2;
    SAMPLETYPE step = 1.0 / (float)envelopeLength;
    VRAMPMUL((SAMPLETYPE*)_scratchBuffer + 1, 2, &start, &step, (SAMPLETYPE*)_scratchBuffer + 1, 2, envelopeLength);
    
    start = 1.0;
    step = -step;
    VRAMPMUL((SAMPLETYPE*)_scratchBuffer + 1 + (envelopeLength*2), 2, &start, &step, (SAMPLETYPE*)_scratchBuffer + 1 + (envelopeLength*2), 2, envelopeLength);
    
    // Assign midpoint
    SAMPLETYPE midpoint = self.bounds.size.height / 2.0;
    VSADD((SAMPLETYPE*)_scratchBuffer+1, 2, &midpoint, (SAMPLETYPE*)_scratchBuffer+1, 2, sampleCount);
    
    // Render lines
    CGContextBeginPath(ctx);
    CGContextAddLines(ctx, (CGPoint*)_scratchBuffer, sampleCount);
    CGContextStrokePath(ctx);
     */
}
