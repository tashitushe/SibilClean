import SwiftUI

struct AppRowView: View {
    @Bindable var app: AppItem

    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: $app.isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()

            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(app.bundleID ?? app.path.path)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textFaint)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if app.isSizeLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(ByteFormat.string(app.totalSize))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                    if app.isScanning {
                        Text("Scanning leftovers…")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textFaint)
                    } else if app.isScanned, !app.leftovers.isEmpty {
                        Text("+\(app.leftovers.count) leftover files")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textFaint)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
