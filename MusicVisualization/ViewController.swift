//
//  ViewController.swift
//  MusicVisualization
//
//  Created by 黃柏叡 on 2017/8/8.
//  Copyright © 2017年 黃柏叡. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate


class ViewController: UIViewController {
    
    var magnitudes:[Float]?
    
    let audioNode = AVAudioPlayerNode()
    lazy var engine = AVAudioEngine()
    lazy var mixer = AVAudioMixerNode()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let input = engine.inputNode!
        let output = engine.outputNode
        
        engine.attach(mixer)
        mixer.installTap(onBus: 0, bufferSize: 64, format: input.inputFormat(forBus: 0)) { (buffer, when) in
            self.performFFT(buffer: buffer)
        }
        
        engine.connect(input, to: mixer, format: input.inputFormat(forBus: 0))
        engine.connect(mixer, to: output, format: input.inputFormat(forBus: 0))
    }
    
    func start() {
        try! engine.start()
    }
    
    func stop() {
        mixer.removeTap(onBus: 0)
        engine.stop()
    }
    
    @IBAction func control(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.isSelected == true ? start() : stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //FFTPerform
    func performFFT(buffer: AVAudioPCMBuffer) {
        let frameCount = buffer.frameLength
        let log2n = UInt(round(log2(Double(frameCount))))
        let bufferSizePOT = Int(1 << log2n)
        let inputCount = bufferSizePOT / 2
        let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))
        
        var realp = [Float](repeating: 0, count: inputCount)
        var imagp = [Float](repeating: 0, count: inputCount)
        var output = DSPSplitComplex(realp: &realp, imagp: &imagp)
        
        let windowSize = bufferSizePOT
        var transferBuffer = [Float](repeating: 0, count: windowSize)
        var window = [Float](repeating: 0, count: windowSize)
        
        // Hann windowing to reduce the frequency leakage
        vDSP_hann_window(&window, vDSP_Length(windowSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul((buffer.floatChannelData?.pointee)!, 1, window,
                  1, &transferBuffer, 1, vDSP_Length(windowSize))
        
        // Transforming the [Float] buffer into a UnsafePointer<Float> object for the vDSP_ctoz method
        // And then pack the input into the complex buffer (output)
        let temp = UnsafePointer<Float>(transferBuffer)
        temp.withMemoryRebound(to: DSPComplex.self,
                               capacity: transferBuffer.count) {
                                vDSP_ctoz($0, 2, &output, 1, vDSP_Length(inputCount))
        }
        
        // Perform the FFT
        vDSP_fft_zrip(fftSetup!, &output, 1, log2n, FFTDirection(FFT_FORWARD))
        
        var magnitudes = [Float](repeating: 0.0, count: inputCount)
        vDSP_zvmags(&output, 1, &magnitudes, 1, vDSP_Length(inputCount))
        
        // Normalising
        var normalizedMagnitudes = [Float](repeating: 0.0, count: inputCount)
        vDSP_vsmul(sqrtq(magnitudes), 1, [2.0 / Float(inputCount)],
                   &normalizedMagnitudes, 1, vDSP_Length(inputCount))
        
        self.magnitudes = magnitudes
        print("(\(magnitudes.count))\(magnitudes[15])|\(magnitudes[31])|\(magnitudes[63])")
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    func sqrtq(_ x: [Float]) -> [Float] {
        var results = [Float](repeating: 0.0, count: x.count)
        vvsqrtf(&results, x, [Int32(x.count)])
        
        return results
    }
}

