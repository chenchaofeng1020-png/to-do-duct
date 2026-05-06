#if os(macOS)
import AppKit
import SwiftUI
import SwiftData

@MainActor
private final class QuickCapturePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class MacQuickCapturePanelController {
    private let viewModel: MacQuickCaptureViewModel
    private let panel: NSPanel
    private var localKeyMonitor: Any?

    init(viewModel: MacQuickCaptureViewModel, modelContainer: ModelContainer) {
        self.viewModel = viewModel

        let rootView = MacQuickCaptureView(viewModel: viewModel)
            .modelContainer(modelContainer)

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let panel = QuickCapturePanel(
            contentRect: NSRect(x: 0, y: 0, width: 548, height: 360),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        let contentView = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        contentView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        panel.contentView = contentView

        self.panel = panel
        installLocalKeyMonitor()
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        viewModel.prepareForPresentation()
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func installLocalKeyMonitor() {
        guard localKeyMonitor == nil else { return }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard self.panel.isVisible, self.panel.isKeyWindow else { return event }

            if event.keyCode == 53 {
                self.viewModel.close()
                return nil
            }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if event.keyCode == 36 && flags == [.command, .option] {
                self.viewModel.submitAndKeepOpen()
                return nil
            }

            if event.keyCode == 36 && flags == [.command] {
                self.viewModel.submitAndClose()
                return nil
            }

            if flags == [.command], event.charactersIgnoringModifiers == "1" {
                self.viewModel.selectTarget(.inbox)
                return nil
            }

            if flags == [.command], event.charactersIgnoringModifiers == "2" {
                self.viewModel.selectTarget(.memo)
                return nil
            }

            return event
        }
    }

    deinit {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
    }
}
#endif
