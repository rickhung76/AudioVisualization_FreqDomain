//
//  AudioFileViewController.swift
//  MixerSwift
//
//  Created by 黃柏叡 on 2017/8/9.
//  Copyright © 2017年 Bruce. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

class AudioFileViewController: UIViewController {
    
    @IBOutlet weak var visualizationView: VisualizationView!
    
    @IBOutlet weak var visualizationView2: VisualizationView!

    override func viewDidLoad() {
        super.viewDidLoad()
        visualizationView.delegate = self
        visualizationView2.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    @IBAction func control(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            guard let fileURL = Bundle.main.url(forResource: "testAudio2", withExtension: "mp3") else {
                print("could not read sound file")
                return
            }
            visualizationView.audioURL = fileURL
            visualizationView.start()
        }
        else {
            visualizationView.stop()
        }
    }
    
    @IBAction func control2(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            guard let fileURL = Bundle.main.url(forResource: "testAudio2", withExtension: "mp3") else {
                print("could not read sound file")
                return
            }
            visualizationView2.audioURL = fileURL
            visualizationView2.start()
        }
        else {
            visualizationView2.stop()
        }
    }
}

extension AudioFileViewController: VisualizationViewDelegate {
    func didRenderAudioFile(_ visualizationView: VisualizationView) {
        print("didRenderAudioFile")
    }
    
    func didStartPlayingAudio(_ visualizationView: VisualizationView) {
        print("didStartPlayingAudio")
    }
    
    func didUpdatePlayerDuration(_ atPlayTime: TimeInterval) {
        print("didUpdatePlayerDuration atPlayTime: \(atPlayTime)")
    }
    
    func didStopPlayingAudio(_ visualizationView: VisualizationView) {
        print("didStopPlayingAudio")
    }
}
