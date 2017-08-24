//
//  AudioEngineManager.swift
//  MusicVisualization
//
//  Created by 黃柏叡 on 2017/8/9.
//  Copyright © 2017年 黃柏叡. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

protocol AudioEngineManagerDelegate {
    func didUpdateFrequncyValues(frequncyValues: [Float])
    func didFinish()
}

class AudioEngineManager: NSObject {
    var delegate: AudioEngineManagerDelegate?
    var isPlayerSource = false
    var FFTSampleCount: Int = 0
    lazy var engine = AVAudioEngine()
    lazy var playerNode = AVAudioPlayerNode()
    lazy var mixerNode = AVAudioMixerNode()
    var audioBuffer:AVAudioPCMBuffer!
    var audioBufferFormat:AVAudioFormat!
    var audioMaxValue: Float = 1.0
    var magnitudes:[Float] = [0] {
        didSet {
            DispatchQueue.main.async(execute: { () -> Void in
                guard self.delegate != nil else {
                    print("AudioEngineManagerDelegate is nil")
                    return
                }
                self.delegate?.didUpdateFrequncyValues(frequncyValues: self.magnitudes)
            })
        }
    }
    
    func readFileIntoBuffer(fileURL: URL) {
        isPlayerSource = true
        do {
            let file = try AVAudioFile(forReading: fileURL)
            audioBufferFormat = file.processingFormat
            audioBuffer = AVAudioPCMBuffer(pcmFormat: audioBufferFormat, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: audioBuffer)
            
            setupAudioEngineWithPlayerNode()
        } catch {
            print("could not create AVAudioPCMBuffer \(error)")
            return
        }
    }
    
    
    func play() {
        if !isPlayerSource {
            setSessionPlayback()
            startAudioEngine()
            return
        }
        if playerNode.isPlaying {
            return
        } else {
            setSessionPlayback()
            startAudioEngine()
            playerNode.scheduleBuffer(audioBuffer, completionHandler: didFinishedPlayingAudio)
            playerNode.play()
        }
    }
    
    func stop() {
        if !isPlayerSource {
            audioMaxValue = 1.0
            engine.stop()
            return
        }
        didFinishedPlayingAudio()
    }
    
    func setupAudioEngineWithMicNode() {
        let input = engine.inputNode!
        let output = engine.outputNode

        engine.attach(mixerNode)
        mixerNode.installTap(onBus: 0, bufferSize: 64, format: input.inputFormat(forBus: 0)) { (buffer, when) in
            self.performFFT(buffer: buffer)
        }
        engine.connect(input, to: mixerNode, format: input.inputFormat(forBus: 0))
        engine.connect(mixerNode, to: output, format: input.inputFormat(forBus: 0))
    }
    
    private func setupAudioEngineWithPlayerNode() {
        engine.stop()
        engine.reset()
        
        engine.attach(playerNode)
        engine.attach(mixerNode)
        
        engine.connect(playerNode, to: mixerNode, format: audioBufferFormat)
        engine.connect(mixerNode, to: engine.outputNode, format: audioBufferFormat)
        
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: audioBufferFormat) { (buffer, time) in
            self.performFFT(buffer: buffer)
        }
        print("Audio engine did set")
    }
    
    func setSessionPlayback() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord,
                                         with: AVAudioSessionCategoryOptions.mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print("couldn't set category \(error)")
        }
    }
    
    private func startAudioEngine() {
        if engine.isRunning {
            print("audio engine already started")
            return
        }
        
        do {
            try engine.start()
            print("audio engine started")
        } catch {
            print("oops \(error)")
            print("could not start audio engine")
        }
    }
    
    private func didFinishedPlayingAudio() {
        if playerNode.isPlaying {
            print("finished playing")
            playerNode.stop()
            engine.stop()
            DispatchQueue.main.async {
                self.delegate?.didFinish()
            }
        }
    }
    
    //FFTPerform
    private func performFFT(buffer: AVAudioPCMBuffer) {
        let frameCount = FFTSampleCount * 2//buffer.frameLength
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
        
        if self.audioMaxValue < magnitudes.max()! {
            self.audioMaxValue = magnitudes.max()!
        }
        
        self.magnitudes = magnitudes.map { $0 / self.audioMaxValue }
//        print("(\(magnitudes.count))(\(self.audioMaxValue))\(magnitudes[1])|\(magnitudes[magnitudes.count/2-1])|\(magnitudes[magnitudes.count-1])")
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    private func sqrtq(_ x: [Float]) -> [Float] {
        var results = [Float](repeating: 0.0, count: x.count)
        vvsqrtf(&results, x, [Int32(x.count)])
        
        return results
    }
}
