import SwiftUI

#if os(macOS)
import AppKit
import Combine

enum MemoListStyle {
    case unordered
    case ordered
}

enum MemoRichTextCodec {
    static func decode(_ data: Data?) -> NSAttributedString? {
        guard let data, !data.isEmpty else { return nil }
        return try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
    }

    static func encode(_ attributedString: NSAttributedString) -> Data? {
        guard attributedString.length > 0 else { return nil }
        return try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
}

enum MemoRichTextFactory {
    static let plainTextColor = DesignSystem.macPrimaryTextColor

    static func baseFont(size: CGFloat) -> NSFont {
        if let descriptor = NSFont.systemFont(ofSize: size).fontDescriptor.withDesign(.rounded) {
            return NSFont(descriptor: descriptor, size: size) ?? .systemFont(ofSize: size)
        }
        return .systemFont(ofSize: size)
    }

    static func makeAttributedString(from text: String, fontSize: CGFloat) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: baseAttributes(fontSize: fontSize)
        )
    }

    static func baseAttributes(fontSize: CGFloat) -> [NSAttributedString.Key: Any] {
        [
            .font: baseFont(size: fontSize),
            .foregroundColor: plainTextColor
        ]
    }
}

@MainActor
final class MacMemoEditorState: ObservableObject {
    weak var textView: NSTextView?

    func apply(_ command: MemoRichTextCommand, fontSize: CGFloat) {
        guard let textView else { return }
        MemoRichTextStyler.apply(command, to: textView, fontSize: fontSize)
    }
}

extension MemoCardV3 {
    func attributedContent(fontSize: CGFloat = 14) -> NSAttributedString {
        if let decoded = MemoRichTextCodec.decode(richTextData) {
            return decoded
        }
        return MemoRichTextFactory.makeAttributedString(from: content, fontSize: fontSize)
    }

    func updateRichContent(_ attributedString: NSAttributedString) {
        let plain = attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
        content = plain
        richTextData = plain.isEmpty ? nil : MemoRichTextCodec.encode(attributedString)
        updatedAt = Date()
    }
}

struct MacAttributedText: NSViewRepresentable {
    let attributedText: NSAttributedString
    let lineLimit: Int?
    let allowsSelection: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false

        let textView = NSTextView()
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = allowsSelection
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.maximumNumberOfLines = lineLimit ?? 0
        textView.textContainer?.lineBreakMode = .byTruncatingTail
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.textStorage?.setAttributedString(attributedText)
        textView.isSelectable = allowsSelection
        textView.textContainer?.maximumNumberOfLines = lineLimit ?? 0
        textView.textContainer?.lineBreakMode = lineLimit == nil ? .byWordWrapping : .byTruncatingTail
    }
}

enum MemoRichTextCommand {
    case toggleBold
    case setColor(NSColor)
    case applyList(MemoListStyle)
}

enum MemoRichTextStyler {
    static func apply(_ command: MemoRichTextCommand, to textView: NSTextView, fontSize: CGFloat) {
        switch command {
        case .toggleBold:
            toggleBold(in: textView, fontSize: fontSize)
        case .setColor(let color):
            setColor(color, in: textView)
        case .applyList(let style):
            applyList(style, in: textView)
        }
    }

    private static func toggleBold(in textView: NSTextView, fontSize: CGFloat) {
        let range = selectedOrCurrentWordRange(in: textView)
        guard range.length > 0, let storage = textView.textStorage else { return }

        storage.beginEditing()
        storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let currentFont = (value as? NSFont) ?? MemoRichTextFactory.baseFont(size: fontSize)
            let boldTrait: NSFontDescriptor.SymbolicTraits = .bold
            let nextFont: NSFont
            if currentFont.fontDescriptor.symbolicTraits.contains(boldTrait) {
                let unboldDescriptor = currentFont.fontDescriptor.withSymbolicTraits(currentFont.fontDescriptor.symbolicTraits.subtracting([boldTrait]))
                nextFont = NSFont(descriptor: unboldDescriptor, size: currentFont.pointSize) ?? MemoRichTextFactory.baseFont(size: fontSize)
            } else {
                let boldDescriptor = currentFont.fontDescriptor.withSymbolicTraits(currentFont.fontDescriptor.symbolicTraits.union([boldTrait]))
                nextFont = NSFont(descriptor: boldDescriptor, size: currentFont.pointSize) ?? NSFont.boldSystemFont(ofSize: currentFont.pointSize)
            }
            storage.addAttribute(.font, value: nextFont, range: subrange)
        }
        storage.endEditing()
        textView.didChangeText()
    }

    private static func setColor(_ color: NSColor, in textView: NSTextView) {
        let range = selectedOrCurrentWordRange(in: textView)
        guard range.length > 0, let storage = textView.textStorage else { return }
        storage.addAttribute(.foregroundColor, value: color, range: range)
        textView.didChangeText()
    }

    private static func applyList(_ style: MemoListStyle, in textView: NSTextView) {
        let selectedRange = textView.selectedRange()
        let nsText = textView.string as NSString
        let paragraphRange = nsText.paragraphRange(for: selectedRange)
        let paragraphText = nsText.substring(with: paragraphRange)
        let lines = paragraphText.components(separatedBy: .newlines)

        var nextIndex = 1
        let mapped = lines.map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return line }
            let raw = trimmed.replacingOccurrences(of: #"^([-•]\s+|\d+\.\s+)"#, with: "", options: .regularExpression)
            defer { nextIndex += 1 }
            switch style {
            case .unordered:
                return "• \(raw)"
            case .ordered:
                return "\(nextIndex). \(raw)"
            }
        }.joined(separator: "\n")

        let replacement = NSAttributedString(
            string: mapped,
            attributes: MemoRichTextFactory.baseAttributes(fontSize: textView.font?.pointSize ?? 16)
        )

        textView.textStorage?.beginEditing()
        textView.textStorage?.replaceCharacters(in: paragraphRange, with: replacement)
        textView.textStorage?.endEditing()
        textView.setSelectedRange(NSRange(location: paragraphRange.location, length: replacement.length))
        textView.didChangeText()
    }

    private static func selectedOrCurrentWordRange(in textView: NSTextView) -> NSRange {
        let selected = textView.selectedRange()
        if selected.length > 0 {
            return selected
        }

        let nsText = textView.string as NSString
        guard nsText.length > 0 else { return selected }
        let safeLocation = max(0, min(selected.location, max(nsText.length - 1, 0)))
        return wordRange(in: nsText, at: safeLocation)
    }

    private static func wordRange(in text: NSString, at location: Int) -> NSRange {
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        var start = location
        var end = location

        while start > 0 {
            guard let scalar = UnicodeScalar(text.character(at: start - 1)) else { break }
            if separators.contains(scalar) { break }
            start -= 1
        }

        while end < text.length {
            guard let scalar = UnicodeScalar(text.character(at: end)) else { break }
            if separators.contains(scalar) { break }
            end += 1
        }

        return NSRange(location: start, length: max(0, end - start))
    }
}
#endif
