//
//  VisualizationView.swift
//  MusicVisualization
//
//  Created by 黃柏叡 on 2017/8/10.
//  Copyright © 2017年 黃柏叡. All rights reserved.
//

import UIKit

@objc public protocol VisualizationViewDelegate: NSObjectProtocol {
    @objc optional func didRenderAudioFile(_ visualizationView: VisualizationView)
    @objc optional func didStartPlayingAudio(_ visualizationView: VisualizationView)
    @objc optional func didStopPlayingAudio(_ visualizationView: VisualizationView)
}

public class VisualizationView: UIView, AudioEngineManagerDelegate {
    var delegate: VisualizationViewDelegate?
    
    var audioURL: URL? {
        didSet {
            guard let audioURL = audioURL else {
                print("VisualizationView received nil audioURL")
                manager = nil
                return
            }
            manager = AudioEngineManager()
            manager?.delegate = self
            manager?.FFTSampleCount = barCount
            manager?.readFileIntoBuffer(fileURL: audioURL)
            self.delegate?.didRenderAudioFile?(self)
        }
    }
    
    var barColor: UIColor {
        get {
            return self.tintColor
        }
        set {
            self.subviews.forEach({ $0.backgroundColor = newValue })
        }
    }
    
    var barWidth = CGFloat(8.0) {
        didSet {
            manager?.FFTSampleCount = barCount
            self.setupBarViews()
        }
    }
    
    var barIntervalWidth = CGFloat(12.0) {
        didSet {
            manager?.FFTSampleCount = barCount
            self.setupBarViews()
        }
    }
    
    private var barCount: Int {
        get {
            return Int(self.frame.size.width / (barWidth + barIntervalWidth))
        }
        set {
            manager?.FFTSampleCount = newValue
        }
    }
    
    private var barViews:[UIView] = []
    
    private var manager: AudioEngineManager?
    
    private var frequncyValues: Array<Float> = [] {
        didSet(freqVals) {
            updateBarFrames()
        }
    }

    func playAudio() {
        guard manager != nil else {
            print("Error playing audio, manager is nil")
            return
        }
        manager?.play()
        self.delegate?.didStartPlayingAudio?(self)
    }
    
    func stopAudio() {
        guard manager != nil else {
            print("Error playing audio, manager is nil")
            return
        }
        manager?.stop()
        self.delegate?.didStopPlayingAudio?(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.updateBarFrames()
    }
    
    func didUpdateFrequncyValues(frequncyValues: [Float]) {
        self.frequncyValues = frequncyValues
    }

    private func initialize() {
        self.setupBarViews()
    }
    
    private func setupBarViews() {
        barViews.removeAll()
        self.subviews.forEach({$0.removeFromSuperview()})
        for _ in 0..<Int(barCount) {
            let view = UIView(frame: CGRect.zero)
            view.backgroundColor = self.tintColor
            barViews.append(view)
            self.addSubview(view)
        }
    }
    
    private func updateBarFrames() {
        
        //Layout the bars based on the updated view frame
        for i in 0 ..< barViews.count {
            let barView = barViews[i]
            var barHeight = CGFloat(1.0)
            let viewHeight = self.frame.size.height
            if frequncyValues.count > i {
                barHeight = viewHeight * CGFloat(self.frequncyValues[i].isNaN ? 1.0 : self.frequncyValues[i]);
                barHeight = ceil(barHeight)
            }
            barView.frame = CGRect(x: CGFloat(i)*(barWidth+barIntervalWidth) + barIntervalWidth/2,
                                   y: (viewHeight-barHeight)/2,
                                   width: barWidth,
                                   height: barHeight);
        }
    }
}
