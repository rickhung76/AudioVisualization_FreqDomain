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
    @objc optional func didUpdatePlayerDuration(_ atPlayTime: TimeInterval)
    @objc optional func didStopPlayingAudio(_ visualizationView: VisualizationView)
}

public class VisualizationView: UIView {
    var delegate: VisualizationViewDelegate?
    
    var enableMicrophone: Bool = false {
        didSet {
            guard enableMicrophone == true else {
                print("VisualizationView enableMicrophone FALSE")
                return
            }
            print("VisualizationView enableMicrophone TRUE")
            manager = AudioEngineManager()
            manager?.delegate = self
            manager?.FFTSampleCount = barCount
            manager?.setupAudioEngineWithMicNode()
            self.delegate?.didRenderAudioFile?(self)
        }
    }
    
    var audioURL: URL? {
        didSet {
            guard let audioURL = audioURL else {
                print("VisualizationView received nil audioURL")
//                manager = nil
                return
            }
            print("VisualizationView received \(audioURL)")
            manager = AudioEngineManager()
            manager?.delegate = self
            manager?.FFTSampleCount = barCount
            manager?.readFileIntoBuffer(fileURL: audioURL)
            self.delegate?.didRenderAudioFile?(self)
        }
    }
    
    @IBInspectable var barColor:UIColor = UIColor.red{
        didSet {
            self.subviews.forEach({ $0.backgroundColor = barColor })
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
    
    var playTime: TimeInterval = 0 {
        didSet {
            self.delegate?.didUpdatePlayerDuration?(playTime)
        }
    }
    
    fileprivate var frequncyValues: Array<Float> = [] {
        didSet(freqVals) {
            updateBarFrames()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.updateBarFrames()
    }

    func playAudio() {
        guard let manager =  manager else {
            print("Error playing audio, manager is nil")
            return
        }
        manager.play()
        self.delegate?.didStartPlayingAudio?(self)
    }
    
    func stopAudio() {
        guard let manager =  manager else {
            print("Error playing audio, manager is nil")
            return
        }
        manager.stop()
        
    }

    private func initialize() {
        self.setupBarViews()
    }
    
    fileprivate func setupBarViews() {
        barViews.removeAll()
        self.subviews.forEach({$0.removeFromSuperview()})
        for _ in 0..<Int(barCount) {
            let view = UIView(frame: CGRect.zero)
            view.backgroundColor = self.barColor
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
            
            UIView.animate(withDuration: TimeInterval(self.bounds.height / 300), animations: {
                barView.frame = CGRect(x: CGFloat(i)*(self.barWidth + self.barIntervalWidth) + self.barIntervalWidth/2,
                                       y: (viewHeight-barHeight)/2,
                                       width: self.barWidth,
                                       height: barHeight);
            })
        }
    }
}

extension VisualizationView:AudioEngineManagerDelegate{
    func didUpdateFrequncyValues(frequncyValues: [Float], atPlayTime: TimeInterval) {
        self.frequncyValues = frequncyValues
    }
    
    func didFinish() {
        self.frequncyValues.removeAll()
        self.delegate?.didStopPlayingAudio?(self)
    }
}
