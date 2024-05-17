//
//  VideoPlayerView.swift
//  Wavecatcher
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    
    private var videoURL: URL
    @State private var videoPlayer: AVQueuePlayer
    @State private var videoPlayerLooper: AVPlayerLooper
    @State private var isOverlayVisible = false
    private let fadeDuration: TimeInterval = 0.5
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    init(videoURL: URL) {
        let playerItem = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        
        self.videoURL = videoURL
        _videoPlayer = .init(initialValue: queuePlayer)
        _videoPlayerLooper = .init(initialValue: AVPlayerLooper(player: queuePlayer, templateItem: playerItem))
    }
    
    var body: some View {
        GeometryReader { proxy in
            VideoPlayerRepresentableView(player: $videoPlayer)
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .onAppear {
                    guard !reduceMotion else { return }
                    videoPlayer.play()
                }
                .onDisappear {
                    videoPlayer.pause()
                }
                .onReceive(applicationBecomeActiveNotificationPublisher) { _ in
                    guard !reduceMotion else { return }
                    videoPlayer.play()
                }
                .onReceive(applicationResignActiveNotificationPublisher) { _ in
                    videoPlayer.pause()
                }
                .overlay {
                    Color.black
                        .opacity(isOverlayVisible ? 1.0 : 0.0)
                        .animation(.linear(duration: fadeDuration), value: videoURL)
                }
        }
        .onChange(of: videoURL) {
            fadeVideoPlayer()
        }
    }
    
    private func fadeVideoPlayer() {
        
        let fadeOutMilliseconds = Int(fadeDuration * 1000)
        let replaceVideoDeadline = DispatchTime.now() + .milliseconds(fadeOutMilliseconds - 100)
        let removeOverlayDeadline = DispatchTime.now() + .milliseconds(fadeOutMilliseconds)
        
        withAnimation {
            isOverlayVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: replaceVideoDeadline) {
            videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
        }
        
        DispatchQueue.main.asyncAfter(deadline: removeOverlayDeadline) {
            withAnimation {
                isOverlayVisible = false
            }
        }
    }
}

#if os(iOS)
import UIKit
extension VideoPlayerView {
    
    var applicationBecomeActiveNotificationPublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
    }
    
    var applicationResignActiveNotificationPublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
    }
    
    struct VideoPlayerRepresentableView: UIViewRepresentable {
        
        @Binding var player: AVQueuePlayer
        
        func makeUIView(context: Context) -> VideoPlayerUIView {
            
            do { // Prevent interrupt audio from other apps
                try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch { }
            
            return VideoPlayerUIView(player: player, videoGravity: .resizeAspectFill)
        }
        
        func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {
            uiView.player = player
        }
    }
    
    final class VideoPlayerUIView: UIView {
        
        var player: AVPlayer {
            didSet {
                playerLayer.player = player
            }
        }
        
        var videoGravity: AVLayerVideoGravity {
            didSet {
                playerLayer.videoGravity = videoGravity
            }
        }
        
        private var playerLayer = AVPlayerLayer()
        
        init(player: AVPlayer, videoGravity: AVLayerVideoGravity) {
            self.player = player
            self.videoGravity = videoGravity
            self.playerLayer.videoGravity = videoGravity
            
            super.init(frame: .zero)
            
            layer.addSublayer(playerLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}
#endif

#if os(macOS)
import AppKit
extension VideoPlayerView {
    
    var applicationBecomeActiveNotificationPublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
    }
    
    var applicationResignActiveNotificationPublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)
    }
    
    struct VideoPlayerRepresentableView: NSViewRepresentable {
        
        @Binding var player: AVQueuePlayer
        
        func makeNSView(context: Context) -> VideoPlayerNSView {
            VideoPlayerNSView(player: player, videoGravity: .resizeAspectFill)
        }
        
        func updateNSView(_ nsView: VideoPlayerNSView, context: Context) {
            nsView.player = player
        }
    }
    
    final class VideoPlayerNSView: NSView {
        
        var player: AVPlayer {
            didSet {
                playerLayer.player = player
            }
        }
        
        var videoGravity: AVLayerVideoGravity {
            didSet {
                playerLayer.videoGravity = videoGravity
            }
        }
        
        private var playerLayer = AVPlayerLayer()
        
        init(player: AVPlayer, videoGravity: AVLayerVideoGravity) {
            self.player = player
            self.videoGravity = videoGravity
            self.playerLayer.videoGravity = videoGravity
            
            super.init(frame: .zero)
            
            self.wantsLayer = true
            self.layer?.backgroundColor = .clear
            self.layer?.addSublayer(playerLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layout() {
            super.layout()
            playerLayer.frame = bounds
        }
        
        override func resizeSubviews(withOldSize oldSize: NSSize) {
            super.resizeSubviews(withOldSize: oldSize)
            playerLayer.frame = bounds
        }
        
        override func viewDidEndLiveResize() {
            super.viewDidEndLiveResize()
            playerLayer.frame = bounds
        }
    }
}
#endif
