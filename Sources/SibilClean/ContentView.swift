import SwiftUI

struct ContentView: View {
    @State private var apps: [AppItem] = []
    @State private var searchText: String = ""
    @State private var isLoading = true
    @State private var showConfirm = false
    @State private var isDeleting = false
    @State private var lastFreedBytes: Int64?

    private var filteredApps: [AppItem] {
        guard !searchText.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var selectedApps: [AppItem] {
        apps.filter(\.isSelected)
    }

    private var selectedTotalSize: Int64 {
        selectedApps.reduce(0) { $0 + $1.totalSize }
    }

    var body: some View {
        ZStack {
            Theme.textPrimary.opacity(0.02).ignoresSafeArea()
            BackdropBlobs().ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if isLoading {
                    Spacer()
                    ProgressView("Scanning installed apps…")
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredApps) { app in
                                AppRowView(app: app)
                                    .onChange(of: app.isSelected) { _, selected in
                                        if selected { scanLeftovers(for: app) }
                                    }
                            }
                        }
                        .padding(16)
                    }
                }

                footer
            }
        }
        .frame(minWidth: 480, minHeight: 560)
        .task { await loadApps() }
        .sheet(isPresented: $showConfirm) {
            ConfirmSheet(
                apps: selectedApps,
                totalSize: selectedTotalSize,
                isDeleting: isDeleting,
                onCancel: { showConfirm = false },
                onConfirm: { performDelete() }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SibilClean")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textFaint)
                TextField("Search apps", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(20)
    }

    private var footer: some View {
        HStack {
            if let lastFreedBytes {
                Label("Freed \(ByteFormat.string(lastFreedBytes))", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.okDot)
                    .font(.system(size: 12, weight: .medium))
            } else if !selectedApps.isEmpty {
                Text("\(selectedApps.count) selected · \(ByteFormat.string(selectedTotalSize))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            Button {
                showConfirm = true
            } label: {
                Label("Remove Selected", systemImage: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(Theme.coral, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .glassEffect(.regular.tint(Theme.coral), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .disabled(selectedApps.isEmpty)
            .opacity(selectedApps.isEmpty ? 0.4 : 1)
        }
        .padding(16)
    }

    private func loadApps() async {
        let scanned = await Task.detached(priority: .userInitiated) {
            AppScanner.scanInstalledApps()
        }.value
        let items = scanned.map { info in
            AppItem(
                name: info.name,
                bundleID: info.bundleID,
                path: info.path,
                icon: NSWorkspace.shared.icon(forFile: info.path.path)
            )
        }
        apps = items
        isLoading = false
        computeSizes(for: items)
    }

    private func computeSizes(for items: [AppItem]) {
        let jobs = items.map { (id: $0.id, path: $0.path) }
        Task {
            await withTaskGroup(of: (String, Int64).self) { group in
                for job in jobs {
                    group.addTask {
                        (job.id, AppScanner.directorySize(at: job.path))
                    }
                }
                for await (id, size) in group {
                    if let app = apps.first(where: { $0.id == id }) {
                        app.appSize = size
                        app.isSizeLoading = false
                    }
                }
            }
        }
    }

    private func scanLeftovers(for app: AppItem) {
        guard !app.isScanned, !app.isScanning else { return }
        app.isScanning = true
        let bundleID = app.bundleID
        let name = app.name
        Task {
            let leftovers = await Task.detached(priority: .utility) {
                AppScanner.findLeftovers(bundleID: bundleID, name: name)
            }.value
            app.leftovers = leftovers
            app.leftoversTotalSize = leftovers.reduce(0) { $0 + $1.size }
            app.isScanning = false
            app.isScanned = true
        }
    }

    private func performDelete() {
        isDeleting = true
        let paths: [URL] = selectedApps.flatMap { [$0.path] + $0.leftovers.map(\.url) }
        let freed = selectedTotalSize
        Task {
            await Task.detached(priority: .userInitiated) {
                for url in paths {
                    try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
                }
            }.value
            apps.removeAll { $0.isSelected }
            lastFreedBytes = freed
            isDeleting = false
            showConfirm = false
        }
    }
}
