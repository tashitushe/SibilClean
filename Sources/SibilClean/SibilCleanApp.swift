import SwiftUI

@main
struct SibilCleanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About SibilClean") { showAboutPanel() }
            }
        }
    }

    private func showAboutPanel() {
        let credits = NSMutableAttributedString(
            string: "https://farnoud.net",
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .link: URL(string: "https://farnoud.net") as Any,
            ]
        )
        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "SibilClean",
            .applicationIcon: NSApplication.shared.applicationIconImage as Any,
            .credits: credits,
        ])
    }
}
