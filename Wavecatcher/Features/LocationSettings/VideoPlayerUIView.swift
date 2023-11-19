//
//  VideoPlayerUIView.swift
//  Wavecatcher
//

import UIKit
import AVFoundation

final class VideoPlayerUIView: UIView {
    
    public var videoURL: URL? {
        didSet {
            guard oldValue != videoURL else { return }
            switch oldValue {
            case .none: initVideo()
            case .some(_): fadeAndInitVideo()
            }
        }
    }
    
    public var isPaused: Bool = false {
        didSet {
            guard oldValue != isPaused else { return }
            isPaused ? videoPlayer.pause() : videoPlayer.play()
        }
    }
    
    private let videoPlayer = AVQueuePlayer()
    private var videoPlayerLooper: AVPlayerLooper?
    
    private let videoPlayerLayer = AVPlayerLayer()
    private let videoPlayerContainerView = UIView()
    private let fadeDuration: TimeInterval = 1.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPlayerContainerView.frame = bounds
        videoPlayerLayer.frame = bounds
    }
    
    private func commonInit() {
        
        backgroundColor = .black
        addSubview(videoPlayerContainerView)
        videoPlayerLayer.player = videoPlayer
        videoPlayerLayer.videoGravity = .resizeAspectFill
        videoPlayerContainerView.layer.addSublayer(videoPlayerLayer)
        
        videoPlayer.isMuted = true
        do {
            // Prevent interrupt audio from other apps
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            
        }
    }
    
    private func initVideo() {
        guard let videoURL else {
            videoPlayerLooper?.disableLooping()
            videoPlayer.replaceCurrentItem(with: nil)
            return
        }
        
        let playerItem = AVPlayerItem(url: videoURL)
        videoPlayer.replaceCurrentItem(with: playerItem)
        videoPlayerLooper = AVPlayerLooper(player: videoPlayer, templateItem: playerItem)
    }
    
    private func fadeAndInitVideo() {
        
        let halfDuration = (fadeDuration / 2.0)
        
        UIView.animate(withDuration: halfDuration) {
            self.videoPlayerContainerView.alpha = 0.0
        } completion: { _ in
            self.initVideo()
            UIView.animate(withDuration: halfDuration) {
                self.videoPlayerContainerView.alpha = 1.0
            }
        }

    }
}
