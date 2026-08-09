import SwiftUI
import PhotosUI

struct HomeView: View {
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var navigateToCrop = false
    @State private var tipIndex = 0

    private let tips = AppTips.all
    private let tipTimer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.pink.opacity(0.28), Color.purple.opacity(0.22)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer(minLength: 12)

                    VStack(spacing: 8) {
                        Text("🐱")
                            .font(.system(size: 76))
                        Text("Kitten Shake")
                            .font(.freckleFace(size: 48))
                            .foregroundStyle(.primary)
                        Text("Shake up your photos with kittens!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(spacing: 16) {
                        Button {
                            SoundPlayer.shared.playClick()
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showCamera = true
                            } else {
                                showPhotoPicker = true
                            }
                        } label: {
                            Label("Take a Photo", systemImage: "camera.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            SoundPlayer.shared.playClick()
                            showPhotoPicker = true
                        } label: {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding(.horizontal, 32)

                    Text(tips[tipIndex])
                        .font(.footnote.italic())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .frame(minHeight: 36)
                        .id(tipIndex)
                        .transition(.opacity)
                        .onReceive(tipTimer) { _ in
                            withAnimation { tipIndex = (tipIndex + 1) % tips.count }
                        }

                    Spacer(minLength: 24)
                }
                .padding()
            }
            .fullScreenCover(isPresented: $showCamera) {
                ImagePickerView(sourceType: .camera) { image in
                    showCamera = false
                    if let image {
                        pickedImage = image
                        navigateToCrop = true
                    }
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photosPickerItem, matching: .images)
            .onChange(of: photosPickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        pickedImage = uiImage
                        navigateToCrop = true
                    }
                    photosPickerItem = nil
                }
            }
            .navigationDestination(isPresented: $navigateToCrop) {
                if let pickedImage {
                    CropView(sourceImage: pickedImage)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
