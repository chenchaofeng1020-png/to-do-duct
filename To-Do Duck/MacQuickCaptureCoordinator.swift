import Foundation
import Combine
import SwiftData

#if os(macOS)
extension Notification.Name {
    static let showMacQuickCapture = Notification.Name("showMacQuickCapture")
    static let macQuickCaptureShortcutDidChange = Notification.Name("macQuickCaptureShortcutDidChange")
}

@MainActor
final class MacQuickCaptureCoordinator: ObservableObject {
    @Published private(set) var shortcut: MacQuickCaptureShortcut

    private let hotkeyService: MacHotkeyService
    private let panelController: MacQuickCapturePanelController
    private let viewModel: MacQuickCaptureViewModel
    private var hasStarted = false
    private var notificationObserver: NSObjectProtocol?
    private var shortcutObserver: NSObjectProtocol?

    init(modelContainer: ModelContainer) {
        let shortcut = MacQuickCaptureShortcut.load()
        let saveService = QuickCaptureSaveService(modelContainer: modelContainer)
        let viewModel = MacQuickCaptureViewModel(saveService: saveService)
        let panelController = MacQuickCapturePanelController(viewModel: viewModel, modelContainer: modelContainer)

        self.shortcut = shortcut
        self.viewModel = viewModel
        self.panelController = panelController
        self.hotkeyService = MacHotkeyService(shortcut: shortcut) { [weak panelController] in
            Task { @MainActor [weak panelController] in
                panelController?.toggle()
            }
        }

        self.viewModel.onRequestClose = { [weak panelController] in
            panelController?.hide()
        }

        self.notificationObserver = NotificationCenter.default.addObserver(
            forName: .showMacQuickCapture,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.show()
            }
        }

        self.shortcutObserver = NotificationCenter.default.addObserver(
            forName: .macQuickCaptureShortcutDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard
                    let self,
                    let shortcut = notification.object as? MacQuickCaptureShortcut
                else {
                    return
                }

                self.shortcut = shortcut
                self.hotkeyService.updateShortcut(shortcut)
            }
        }
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        hotkeyService.register()
    }

    func show() {
        panelController.show()
    }

    deinit {
        if let notificationObserver {
            NotificationCenter.default.removeObserver(notificationObserver)
        }
        if let shortcutObserver {
            NotificationCenter.default.removeObserver(shortcutObserver)
        }
    }
}
#endif
