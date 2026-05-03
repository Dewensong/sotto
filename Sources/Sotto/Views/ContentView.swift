import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            SottoBackground()

            if model.currentDocument == nil {
                HomeView()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                EditorView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: model.currentDocument?.id)
    }
}
