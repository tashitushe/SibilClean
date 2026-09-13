import SwiftUI

struct ConfirmSheet: View {
    let apps: [AppItem]
    let totalSize: Int64
    let isDeleting: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    private var allPaths: [URL] {
        apps.flatMap { [$0.path] + $0.leftovers.map(\.url) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Move to Trash?")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            Text("\(apps.count) app(s) and their related files (\(ByteFormat.string(totalSize))) will be moved to the Trash.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textMuted)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(allPaths, id: \.path) { url in
                        Text(url.path)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.textFaint)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 220)
            .padding(10)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(Theme.textMuted)

                Button {
                    onConfirm()
                } label: {
                    if isDeleting {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Move to Trash")
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(.regular.tint(Theme.coral), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .disabled(isDeleting)
            }
        }
        .padding(22)
        .frame(width: 460)
        .background(Theme.textPrimary.opacity(0.02))
    }
}
