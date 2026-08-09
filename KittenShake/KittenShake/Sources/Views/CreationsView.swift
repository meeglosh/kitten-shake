import SwiftUI

struct CreationsView: View {
    @StateObject private var store = CreationStore.shared
    @State private var selected: Creation?

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: KSTheme.spacingS)]

    var body: some View {
        NavigationStack {
            ZStack {
                KSScreenBackground()

                VStack(spacing: 0) {
                    screenHeader

                    if store.creations.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: KSTheme.spacingS) {
                                ForEach(store.creations) { creation in
                                    Button {
                                        selected = creation
                                    } label: {
                                        thumbnail(for: creation)
                                    }
                                }
                            }
                            .padding(KSTheme.spacingM)
                            .padding(.bottom, 110)
                        }
                        .ksReadableWidth()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { store.reload() }
            .sheet(item: $selected) { creation in
                CreationDetailView(creation: creation, store: store)
            }
        }
    }

    private var screenHeader: some View {
        HStack {
            Text("Creations")
                .font(KSTheme.display(30))
                .foregroundStyle(KSTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, KSTheme.spacingL)
        .padding(.top, KSTheme.spacingM)
        .padding(.bottom, KSTheme.spacingS)
    }

    private func thumbnail(for creation: Creation) -> some View {
        Group {
            if let uiImage = UIImage(contentsOfFile: creation.thumbnailURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .frame(minWidth: 100, minHeight: 100)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(KSTheme.cardBorder, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: KSTheme.spacingM) {
            Spacer()
            Image(systemName: "photo.stack")
                .font(.system(size: 56))
                .foregroundStyle(KSTheme.accent)
            Text("No creations yet")
                .font(KSTheme.display(24))
                .foregroundStyle(KSTheme.textPrimary)
            Text("Shake up a photo and your masterpieces will show up here.")
                .font(.subheadline)
                .foregroundStyle(KSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KSTheme.spacingXL)
            Spacer()
            Spacer()
        }
        .ksReadableWidth()
    }
}

private struct CreationDetailView: View {
    let creation: Creation
    @ObservedObject var store: CreationStore
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ZStack {
                KSScreenBackground()
                VStack(spacing: KSTheme.spacingL) {
                    if let uiImage = UIImage(contentsOfFile: creation.imageURL.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                                    .stroke(KSTheme.cardBorder, lineWidth: 4)
                            )
                            .shadow(color: .black.opacity(0.14), radius: 16, y: 10)
                            .padding(.horizontal, KSTheme.spacingM)
                    }

                    HStack(spacing: KSTheme.spacingM) {
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.ksSecondary)

                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.ksSecondary)
                    }
                    .padding(.horizontal, KSTheme.spacingM)

                    Spacer()
                }
                .padding(.top, KSTheme.spacingL)
                .ksReadableWidth()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let uiImage = UIImage(contentsOfFile: creation.imageURL.path) {
                    ShareSheet(activityItems: [uiImage])
                }
            }
            .confirmationDialog("Delete this creation?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    store.delete(creation)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    CreationsView()
}
