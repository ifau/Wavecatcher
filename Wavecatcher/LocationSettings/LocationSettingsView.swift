//
//  LocationSettingsView.swift
//  Wavecatcher
//

import SwiftUI
import PhotosUI
import ComposableArchitecture

struct LocationSettingsView: View {
    
    private let backgroundPreviewSize = CGSize(width: 150, height: 280)
    @State private var selectedItem: PhotosPickerItem?
    
    let store: StoreOf<LocationSettingsFeature>
    
    init(store: StoreOf<LocationSettingsFeature>) {
        self.store = store
    }
    
    init(state: LocationSettingsFeature.State) {
        self.store = Store(initialState: state, reducer: { LocationSettingsFeature() })
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            List {
                Section(content: {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            auroraView(.variant1, state: viewStore.state)
                            auroraView(.variant2, state: viewStore.state)
                            auroraView(.variant3, state: viewStore.state)
                            auroraView(.variant4, state: viewStore.state)
                            photosPicker(viewStore.state)
                        }
                    }
                    .padding(.top)
                    
                }, header: {
                    Text("Background")
                })
            }
            .onChange(of: selectedItem) {
                viewStore.send(.selectPhotosPickerItem(selectedItem))
            }
            .navigationTitle(viewStore.location.title)
            .toolbar {
                Button("Save", action: { viewStore.send(.saveChanges) })
                    .bold()
                    .disabled(!viewStore.isSaveActionAvailable)
            }
        }
    }
    
    private func auroraView(_ variant: BackgroundVariant.AuroraVariant, state: LocationSettingsFeature.State) -> some View {
        VStack(spacing: 8) {
            AuroraBackgroundView(variant: variant)
                .roundedCorners(.allCorners, radius: 8)
            Image(systemName: (state.selectedBackground == .aurora(variant) ? "checkmark.circle.fill" : "circle"))
                .foregroundStyle(state.selectedBackground == .aurora(variant) ? .primary : .secondary)
        }
        .opacity(state.isLoadingPhotosPickerItem ? 0.5 : 1.0)
        .onTapGesture { store.send(.selectBackground(.aurora(variant)), animation: .smooth) }
        .frame(width: backgroundPreviewSize.width, height: backgroundPreviewSize.height)
    }
    
    private func photosPicker(_ state: LocationSettingsFeature.State) -> some View {
        VStack(spacing: 8) {
            if case .video(let video) = state.selectedBackground, !state.isLoadingPhotosPickerItem {
                VideoPlayerView(videoURL: video.fileURL)
                    .clipped()
                    .overlay { photosPickerOverlay(withLabel: false) }
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.primary)
            } else {
                RoundedRectangle(cornerRadius: 8, style: .circular)
                    .stroke(.secondary, style: StrokeStyle(lineWidth: 2, lineCap: .square, dash: [4, 8]))
                    .overlay {
                        if state.isLoadingPhotosPickerItem {
                            ProgressView()
                        } else {
                            photosPickerOverlay(withLabel: true)
                        }
                    }
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.primary)
                    .hidden()
            }
        }
        .frame(width: backgroundPreviewSize.width, height: backgroundPreviewSize.height)
    }
    
    @ViewBuilder
    private func photosPickerOverlay(withLabel: Bool) -> some View {
        PhotosPicker(selection: $selectedItem, matching: .videos, preferredItemEncoding: .automatic, photoLibrary: .shared(), label: {
            Text(withLabel ? "Select video" : "")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        })
    }
}

#Preview {
    LocationSettingsView(state: .init(location: SavedLocation.previewData.first!, selectedBackground: .aurora(.variant1)))
}
