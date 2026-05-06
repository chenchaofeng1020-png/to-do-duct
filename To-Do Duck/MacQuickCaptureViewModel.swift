import Foundation
import Combine

#if os(macOS)
enum QuickCaptureTarget: String, CaseIterable, Identifiable {
    case inbox
    case memo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox:
            return "收集箱"
        case .memo:
            return "备忘"
        }
    }

    var icon: String {
        switch self {
        case .inbox:
            return "tray.full"
        case .memo:
            return "square.and.pencil"
        }
    }

    var saveSuccessMessage: String {
        switch self {
        case .inbox:
            return "已加入收集箱"
        case .memo:
            return "已保存到备忘"
        }
    }
}

@MainActor
final class MacQuickCaptureViewModel: ObservableObject {
    @Published var selectedTarget: QuickCaptureTarget
    @Published var draftText: String = ""
    @Published var focusToken: UUID = UUID()
    @Published var feedbackMessage: String?
    @Published var isShowingError: Bool = false
    @Published var isContinuousModeEnabled: Bool {
        didSet {
            defaults.set(isContinuousModeEnabled, forKey: continuousModeKey)
        }
    }

    var onRequestClose: (() -> Void)?

    private let saveService: QuickCaptureSaveService
    private let defaults: UserDefaults
    private let selectedTargetKey = "macQuickCaptureSelectedTarget"
    private let continuousModeKey = "macQuickCaptureContinuousMode"

    init(saveService: QuickCaptureSaveService, defaults: UserDefaults = .standard) {
        self.saveService = saveService
        self.defaults = defaults
        self.selectedTarget = QuickCaptureTarget(rawValue: defaults.string(forKey: selectedTargetKey) ?? "") ?? .inbox
        self.isContinuousModeEnabled = defaults.bool(forKey: continuousModeKey)
    }

    var canSubmit: Bool {
        !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func prepareForPresentation() {
        feedbackMessage = nil
        isShowingError = false
        requestFocus()
    }

    func requestFocus() {
        focusToken = UUID()
    }

    func selectTarget(_ target: QuickCaptureTarget) {
        selectedTarget = target
        defaults.set(target.rawValue, forKey: selectedTargetKey)
        feedbackMessage = nil
        isShowingError = false
        requestFocus()
    }

    func submitAndClose() {
        submit(keepOpenOverride: false)
    }

    func submitAndKeepOpen() {
        submit(keepOpenOverride: true)
    }

    func close() {
        feedbackMessage = nil
        isShowingError = false
        onRequestClose?()
    }

    private func submit(keepOpenOverride: Bool) {
        do {
            switch selectedTarget {
            case .inbox:
                try saveService.saveInboxItem(text: draftText)
            case .memo:
                try saveService.saveMemo(text: draftText)
            }

            let keepOpen = keepOpenOverride || isContinuousModeEnabled
            draftText = ""
            feedbackMessage = keepOpen ? selectedTarget.saveSuccessMessage : nil
            isShowingError = false

            if keepOpen {
                requestFocus()
            } else {
                onRequestClose?()
            }
        } catch {
            feedbackMessage = (error as? LocalizedError)?.errorDescription ?? "保存失败，请重试"
            isShowingError = true
            requestFocus()
        }
    }
}
#endif
