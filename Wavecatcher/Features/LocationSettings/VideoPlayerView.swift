//
//  VideoPlayerView.swift
//  Wavecatcher
//

import SwiftUI

struct VideoPlayerView: View {
    @State private var isPaused = true
    private var videoURL: URL?
    
    init(videoURL: URL?) {
        self.videoURL = videoURL
    }
    
    var body: some View {
        GeometryReader { proxy in
            VideoPlayerUIViewRepresentable(videoURL: videoURL, isPaused: isPaused)
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .onAppear {
                    isPaused = false
                }
                .onDisappear {
                    isPaused = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    isPaused = false
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    isPaused = true
                }
        }
    }
}

extension VideoPlayerView {
    
    struct VideoPlayerUIViewRepresentable: UIViewRepresentable {
        
        let videoURL: URL?
        let isPaused: Bool
        
        func makeUIView(context: Context) -> VideoPlayerUIView {
            
            return VideoPlayerUIView()
        }
        
        func updateUIView(_ uiView: VideoPlayerUIView, context: UIViewRepresentableContext<VideoPlayerUIViewRepresentable>) {
            uiView.videoURL = videoURL
            uiView.isPaused = isPaused
        }
    }
}
