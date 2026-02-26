import SwiftUI

struct WelcomeView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App Icon & Title
            VStack(spacing: 12) {
                Image(nsImage: AppLogo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                Text("Welcome to BoboMind")
                    .font(.system(.title, design: .rounded, weight: .bold))

                Text("Your smart clipboard history manager")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 32)

            // Features
            VStack(alignment: .leading, spacing: 16) {
                featureRow(
                    icon: "doc.on.clipboard",
                    color: .blue,
                    title: "Clipboard History",
                    description: "Everything you copy is automatically saved and searchable."
                )
                featureRow(
                    icon: "command",
                    color: .orange,
                    title: "Global Shortcut",
                    description: "Press ⌘⇧V from any app to instantly access your history."
                )
                featureRow(
                    icon: "magnifyingglass",
                    color: .green,
                    title: "Smart Search",
                    description: "Find any clip with exact, fuzzy, or regex search."
                )
                featureRow(
                    icon: "lock.shield",
                    color: .purple,
                    title: "Privacy First",
                    description: "All data stays on your Mac. No cloud, no tracking, no analytics."
                )
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 32)

            // Privacy notice
            Text("BoboMind monitors your clipboard to save history. Copies from password managers are automatically ignored. You can exclude any app in Settings.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // CTA
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, weight: .semibold))
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
