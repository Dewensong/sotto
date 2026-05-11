import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack(alignment: .top) {
            SottoStageBackground(intensity: model.currentDocument == nil && model.phase != .preparing ? 0.72 : 1)

            Group {
                if model.phase == .preparing {
                    PreparingView()
                        .transition(.opacity.combined(with: .scale(scale: 0.985)))
                } else if model.phase == .documentManager {
                    DocumentManagerView()
                        .transition(.opacity.combined(with: .scale(scale: 0.985)))
                } else if model.currentDocument == nil {
                    HomeView()
                        .transition(.opacity.combined(with: .scale(scale: 0.985)))
                } else {
                    EditorView()
                        .transition(.opacity)
                }
            }
            .blur(radius: model.showSettingsPanel ? 6 : 0)

            if model.showSettingsPanel {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.toggleSettingsPanel()
                    }
                    .zIndex(10)

                VStack {
                    HStack {
                        Spacer()
                        SottoSettingsPanel()
                            .environmentObject(model)
                            .padding(.trailing, 28)
                    }
                    .padding(.top, model.currentDocument == nil ? 132 : 116)
                    Spacer()
                }
                .zIndex(20)
                .transition(.opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
            }

            SottoSaveToast(toast: model.toast)
                .zIndex(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.easeInOut(duration: 0.22), value: model.currentDocument?.id)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: model.showSettingsPanel)
        .animation(.spring(response: 0.40, dampingFraction: 0.72), value: model.toast)
    }
}

// MARK: - Toast

enum SottoToastKind: Equatable {
    case success
    case error
}

struct SottoToastMessage: Equatable {
    let text: String
    let kind: SottoToastKind
}

private struct SottoSaveToast: View {
    let toast: SottoToastMessage?
    @State private var visible = false

    private var isError: Bool {
        if case .error = toast?.kind { return true }
        return false
    }

    var body: some View {
        VStack {
            if let toast, visible {
                HStack(spacing: 9) {
                    Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(toast.text)
                        .font(SottoFont.pixel(12))
                        .tracking(1.2)
                }
                .foregroundStyle(isError ? Color.sottoRed : Color.sottoPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isError ? Color.sottoRed.opacity(0.10) : Color.sottoGlow.opacity(0.13))
                )
                .overlay(
                    Capsule()
                        .stroke(isError ? Color.sottoRed.opacity(0.28) : Color.sottoGlow.opacity(0.24), lineWidth: 1)
                )
                .shadow(color: (isError ? Color.sottoRed : Color.sottoGlow).opacity(0.18), radius: 14, y: 4)
                .transition(.opacity.combined(with: .scale(scale: 0.88)).combined(with: .offset(y: -12)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, 28)
        .onChange(of: toast?.text) {
            if toast != nil {
                withAnimation(.spring(response: 0.40, dampingFraction: 0.72)) {
                    visible = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.28)) {
                    visible = false
                }
            }
        }
    }
}
