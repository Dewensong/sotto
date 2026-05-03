import SwiftUI
import SottoCore

struct TeleprompterWindowView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            SottoBackground(isSubtle: true)
            VStack(spacing: 18) {
                HStack {
                    Text("SOTTO PROMPT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.sottoGlow)
                    Spacer()
                    Text(model.session?.isPlaying == true ? "ON AIR" : "PAUSED")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.sottoMuted)
                }

                PromptLinesView()

                HStack(spacing: 14) {
                    Button { model.previousSentence() } label: { Image(systemName: "backward.end.fill") }
                    Button { model.togglePlayback() } label: { Image(systemName: model.session?.isPlaying == true ? "pause.fill" : "play.fill") }
                    Button { model.nextSentence() } label: { Image(systemName: "forward.end.fill") }

                    Divider().frame(height: 20).overlay(.white.opacity(0.18))

                    ForEach(TimingProfile.allCases) { profile in
                        Button(profile.title) { model.setTiming(profile) }
                            .foregroundStyle(model.timing == profile ? Color.sottoPrimary : Color.sottoMuted)
                    }

                    Spacer()

                    Button { model.closeTeleprompter() } label: { Image(systemName: "xmark") }
                }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.sottoSecondary)
                .opacity(0.82)
            }
            .padding(24)
        }
        .frame(width: model.settings.width)
        .frame(minHeight: 380)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.sottoGlow.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: Color.sottoGlow.opacity(0.20), radius: 30, y: 10)
        .opacity(model.settings.opacity)
        .onReceive(Timer.publish(every: 1.1, on: .main, in: .common).autoconnect()) { _ in
            model.advancePhrase()
        }
    }
}
