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

    override func viewDidLoad() {
        super.viewDidLoad()
        visualizationView.initAudioEngineManager()
        visualizationView.delegate = self
    }
    
    @IBAction func control(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            guard let fileURL = Bundle.main.url(forResource: "testAudio2", withExtension: "mp3") else {
                print("could not read sound file")
                return
            }
            visualizationView.audioURL = fileURL
            visualizationView.playAudio()
        }
        else {
            visualizationView.stopAudio()
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
    
    func didStopPlayingAudio(_ visualizationView: VisualizationView) {
        print("didStopPlayingAudio")
    }
}
