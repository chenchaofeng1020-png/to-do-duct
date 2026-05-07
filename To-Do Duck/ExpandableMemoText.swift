import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if os(macOS)
import AppKit

struct ExpandableMemoText: View {
    private let attributedContent: NSAttributedString?
    private let markdownContent: String?
    private let font: Font
    private let lineSpacing: CGFloat
    private let textColor: Color
    var maxLines: Int = 6
    var allowsSelection: Bool = false

    init(attributedContent: NSAttributedString, maxLines: Int = 6, allowsSelection: Bool = false) {
        self.attributedContent = attributedContent
        self.markdownContent = nil
        self.font = .system(size: 14, weight: .medium, design: .rounded)
        self.lineSpacing = 4
        self.textColor = DesignSystem.onSurface
        self.maxLines = maxLines
        self.allowsSelection = allowsSelection
    }

    init(
        content: String,
        font: Font,
        lineSpacing: CGFloat,
        textColor: Color,
        maxLines: Int = 6,
        allowsSelection: Bool = false
    ) {
        self.attributedContent = nil
        self.markdownContent = content
        self.font = font
        self.lineSpacing = lineSpacing
        self.textColor = textColor
        self.maxLines = maxLines
        self.allowsSelection = allowsSelection
    }

    var body: some View {
        visibleText
    }

    @ViewBuilder
    private var visibleText: some View {
        if let renderedAttributedText = renderedAttributedText {
            if let converted = try? AttributedString(renderedAttributedText, including: \.appKit) {
                let text = Text(converted)
                    .lineSpacing(lineSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if allowsSelection {
                    text.textSelection(.enabled)
                } else {
                    text
                }
            } else {
                Text(renderedAttributedText.string)
                    .font(font)
                    .foregroundColor(textColor)
                    .lineSpacing(lineSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text(markdownContent ?? "")
                .font(font)
                .foregroundColor(textColor)
                .lineSpacing(lineSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var renderedAttributedText: NSAttributedString? {
        if let attributedContent {
            return attributedContent
        }

        guard let markdownContent else { return nil }
        return MemoMarkdownRenderer.renderMacAttributedString(markdownContent, fontSize: 14)
    }
}

#else
struct ExpandableMemoText: View {
    private let attributedContent: NSAttributedString?
    private let content: String?
    private let font: Font
    private let lineSpacing: CGFloat
    private let textColor: Color
    var maxLines: Int = 6
    var allowsSelection: Bool = false

    @State private var isExpanded = false
    @State private var measuredContentHeight: CGFloat = 0
    private let collapsedMaxHeight: CGFloat = 180

    init(attributedContent: NSAttributedString, maxLines: Int = 6, allowsSelection: Bool = false) {
        self.attributedContent = attributedContent
        self.content = nil
        self.font = .system(size: 14, weight: .medium, design: .rounded)
        self.lineSpacing = 4
        self.textColor = DesignSystem.onSurface
        self.maxLines = maxLines
        self.allowsSelection = allowsSelection
    }

    init(
        content: String,
        font: Font,
        lineSpacing: CGFloat,
        textColor: Color,
        maxLines: Int = 6,
        allowsSelection: Bool = false
    ) {
        self.attributedContent = nil
        self.content = content
        self.font = font
        self.lineSpacing = lineSpacing
        self.textColor = textColor
        self.maxLines = maxLines
        self.allowsSelection = allowsSelection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            visibleText
                .frame(maxHeight: isExpanded ? nil : collapsedMaxHeight, alignment: .top)
                .clipped()
                .background(measurementLayer)

            if shouldShowToggle {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(LocalizedStringKey(isExpanded ? "collapse_memo_content" : "expand_memo_content"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignSystem.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: content ?? attributedContent?.string ?? "") {
            isExpanded = false
        }
    }

    @ViewBuilder
    private var visibleText: some View {
        let text = renderedText
            .font(font)
            .foregroundColor(textColor)
            .lineSpacing(lineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)

        if allowsSelection {
            text.textSelection(.enabled)
        } else {
            text
        }
    }

    private var renderedText: Text {
        if let attributedContent,
           let converted = MemoMarkdownRenderer.normalizedIOSAttributedString(from: attributedContent) {
            return Text(converted)
        }

        if let content,
           let renderedMarkdown = MemoMarkdownRenderer.renderIOSAttributedString(content, fontSize: 14),
           let converted = try? AttributedString(renderedMarkdown, including: \.uiKit) {
            return Text(converted)
        }

        return Text(content ?? attributedContent?.string ?? "")
    }

    private var shouldShowToggle: Bool {
        measuredContentHeight > collapsedMaxHeight + 1
    }

    private var measurementLayer: some View {
        renderedText
            .font(font)
            .foregroundColor(textColor)
            .lineSpacing(lineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: MemoTextHeightPreferenceKey.self, value: proxy.size.height)
                }
            )
            .hidden()
            .onPreferenceChange(MemoTextHeightPreferenceKey.self) { height in
                measuredContentHeight = height
            }
    }
}
#endif

private struct MemoTextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private enum MemoMarkdownRenderer {
    static func render(_ content: String) -> AttributedString? {
        guard !content.isEmpty else { return nil }
        let normalizedContent = normalizeLineBreaks(in: content)
        return try? AttributedString(
            markdown: normalizedContent,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        )
    }

    private static func normalizeLineBreaks(in content: String) -> String {
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.components(separatedBy: "\n")

        return lines.enumerated().map { index, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isLastLine = index == lines.count - 1
            let nextLine = isLastLine ? "" : lines[index + 1].trimmingCharacters(in: .whitespaces)

            guard !isLastLine else { return line }
            guard !trimmed.isEmpty else { return line }
            guard !nextLine.isEmpty else { return line }
            guard !isMarkdownBlockLine(trimmed), !isMarkdownBlockLine(nextLine) else { return line }

            return line + "  "
        }
        .joined(separator: "\n")
    }

    private static func isMarkdownBlockLine(_ line: String) -> Bool {
        guard !line.isEmpty else { return false }

        if line.hasPrefix("#") || line.hasPrefix(">") || line.hasPrefix("```") {
            return true
        }

        if line.range(of: #"^(\-|\*|\+)\s+"#, options: .regularExpression) != nil {
            return true
        }

        if line.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil {
            return true
        }

        return false
    }

    #if canImport(UIKit)
    static func normalizedIOSAttributedString(from attributedString: NSAttributedString, fontSize: CGFloat = 14) -> AttributedString? {
        guard attributedString.length > 0 else { return nil }

        let normalized = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: normalized.length)

        normalized.enumerateAttributes(in: fullRange) { attributes, range, _ in
            let originalFont = attributes[.font] as? UIFont
            let isBold = originalFont?.fontDescriptor.symbolicTraits.contains(.traitBold) ?? false
            normalized.addAttribute(
                .font,
                value: roundedUIFont(size: fontSize, weight: isBold ? .semibold : .medium),
                range: range
            )

            if attributes[.foregroundColor] == nil {
                normalized.addAttribute(.foregroundColor, value: defaultIOSMemoTextColor, range: range)
            }
        }

        return try? AttributedString(normalized, including: \.uiKit)
    }

    static func renderIOSAttributedString(_ content: String, fontSize: CGFloat) -> NSAttributedString? {
        let normalized = normalizeLineBreaks(in: content)
        guard !normalized.isEmpty else { return nil }

        let result = NSMutableAttributedString()
        let lines = normalized.components(separatedBy: "\n")

        for index in lines.indices {
            result.append(parseIOSLine(lines[index], fontSize: fontSize))
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }

        return result
    }

    private static func parseIOSLine(_ line: String, fontSize: CGFloat) -> NSAttributedString {
        let headingPattern = #"^\s*(#{1,6})\s*(.+)$"#
        let orderedPattern = #"^\s*(\d+)\.\s*(.+)$"#
        let unorderedPattern = #"^\s*([\-+*])(?!\1)\s*(.+)$"#

        if let match = regexMatch(line, pattern: headingPattern) {
            return parseInlineIOSMarkdown(
                in: match[2],
                font: roundedUIFont(size: fontSize, weight: .semibold),
                boldFont: roundedUIFont(size: fontSize, weight: .bold)
            )
        }

        if let match = regexMatch(line, pattern: orderedPattern) {
            return listItemIOSAttributedString(prefix: "\(match[1]).", content: match[2], fontSize: fontSize)
        }

        if let match = regexMatch(line, pattern: unorderedPattern) {
            return listItemIOSAttributedString(prefix: "•", content: match[2], fontSize: fontSize)
        }

        return parseInlineIOSMarkdown(
            in: line,
            font: roundedUIFont(size: fontSize, weight: .medium),
            boldFont: roundedUIFont(size: fontSize, weight: .semibold)
        )
    }

    private static func listItemIOSAttributedString(prefix: String, content: String, fontSize: CGFloat) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 22

        let result = NSMutableAttributedString(
            string: "\(prefix) ",
            attributes: [
                .font: roundedUIFont(size: fontSize, weight: .medium),
                .foregroundColor: defaultIOSMemoTextColor,
                .paragraphStyle: paragraphStyle
            ]
        )

        let contentText = NSMutableAttributedString(
            attributedString: parseInlineIOSMarkdown(
                in: content,
                font: roundedUIFont(size: fontSize, weight: .medium),
                boldFont: roundedUIFont(size: fontSize, weight: .semibold)
            )
        )
        contentText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: contentText.length))
        result.append(contentText)
        return result
    }

    private static func parseInlineIOSMarkdown(in line: String, font: UIFont, boldFont: UIFont) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let nsLine = line as NSString
        let pattern = #"\*\*(.+?)\*\*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return iosAttributedString(line, font: font)
        }

        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        guard !matches.isEmpty else {
            return iosAttributedString(line, font: font)
        }

        var cursor = 0
        for match in matches {
            let fullRange = match.range(at: 0)
            let contentRange = match.range(at: 1)

            if fullRange.location > cursor {
                result.append(iosAttributedString(nsLine.substring(with: NSRange(location: cursor, length: fullRange.location - cursor)), font: font))
            }

            result.append(iosAttributedString(nsLine.substring(with: contentRange), font: boldFont))
            cursor = fullRange.location + fullRange.length
        }

        if cursor < nsLine.length {
            result.append(iosAttributedString(nsLine.substring(from: cursor), font: font))
        }

        return result
    }

    private static func iosAttributedString(_ string: String, font: UIFont) -> NSAttributedString {
        NSAttributedString(
            string: string,
            attributes: [
                .font: font,
                .foregroundColor: defaultIOSMemoTextColor
            ]
        )
    }

    private static func regexMatch(_ line: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsLine = line as NSString
        let range = NSRange(location: 0, length: nsLine.length)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }

        return (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return "" }
            return nsLine.substring(with: range)
        }
    }

    private static func roundedUIFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = baseFont.fontDescriptor.withDesign(.rounded) else {
            return baseFont
        }
        return UIFont(descriptor: descriptor, size: size)
    }

    private static var defaultIOSMemoTextColor: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 224/255, green: 227/255, blue: 225/255, alpha: 1)
            }
            return UIColor(red: 45/255, green: 52/255, blue: 50/255, alpha: 1)
        }
    }
    #endif

    #if os(macOS)
    static func renderMacAttributedString(_ content: String, fontSize: CGFloat) -> NSAttributedString? {
        let normalized = normalizeLineBreaks(in: content)
        guard !normalized.isEmpty else { return nil }

        let result = NSMutableAttributedString()
        let lines = normalized.components(separatedBy: "\n")

        for index in lines.indices {
            let parsedLine = parseMacLine(lines[index], fontSize: fontSize)
            result.append(parsedLine)
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }

        return result
    }

    private static func parseMacLine(_ line: String, fontSize: CGFloat) -> NSAttributedString {
        let headingPattern = #"^\s*(#{1,6})\s*(.+)$"#
        let orderedPattern = #"^\s*(\d+)\.\s*(.+)$"#
        let unorderedPattern = #"^\s*([\-+*])(?!\1)\s*(.+)$"#

        if let match = regexMatch(line, pattern: headingPattern) {
            let content = match[2]
            return parseInlineMacMarkdown(
                in: content,
                font: MemoRichTextFactory.baseFont(size: fontSize),
                boldFont: boldVariant(of: MemoRichTextFactory.baseFont(size: fontSize))
            )
        }

        if let match = regexMatch(line, pattern: orderedPattern) {
            let number = match[1]
            let content = match[2]
            return listItemAttributedString(
                prefix: "\(number).",
                content: content,
                fontSize: fontSize
            )
        }

        if let match = regexMatch(line, pattern: unorderedPattern) {
            let content = match[2]
            return listItemAttributedString(
                prefix: "•",
                content: content,
                fontSize: fontSize
            )
        }

        return parseInlineMacMarkdown(
            in: line,
            font: MemoRichTextFactory.baseFont(size: fontSize),
            boldFont: boldVariant(of: MemoRichTextFactory.baseFont(size: fontSize))
        )
    }

    private static func regexMatch(_ line: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsLine = line as NSString
        let range = NSRange(location: 0, length: nsLine.length)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }

        return (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return "" }
            return nsLine.substring(with: range)
        }
    }

    private static func listItemAttributedString(prefix: String, content: String, fontSize: CGFloat) -> NSAttributedString {
        let baseFont = MemoRichTextFactory.baseFont(size: fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 24

        let result = NSMutableAttributedString(
            string: "\(prefix) ",
            attributes: [
                .font: baseFont,
                .foregroundColor: MemoRichTextFactory.plainTextColor,
                .paragraphStyle: paragraphStyle
            ]
        )

        let contentText = NSMutableAttributedString(
            attributedString: parseInlineMacMarkdown(
                in: content,
                font: baseFont,
                boldFont: boldVariant(of: baseFont)
            )
        )
        contentText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: contentText.length))
        result.append(contentText)
        return result
    }

    private static func parseInlineMacMarkdown(in line: String, font: NSFont, boldFont: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let nsLine = line as NSString
        let pattern = #"\*\*(.+?)\*\*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return NSAttributedString(
                string: line,
                attributes: [.font: font, .foregroundColor: MemoRichTextFactory.plainTextColor]
            )
        }

        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        if matches.isEmpty {
            return NSAttributedString(
                string: line,
                attributes: [.font: font, .foregroundColor: MemoRichTextFactory.plainTextColor]
            )
        }

        var cursor = 0
        for match in matches {
            let fullRange = match.range(at: 0)
            let contentRange = match.range(at: 1)

            if fullRange.location > cursor {
                let plainText = nsLine.substring(with: NSRange(location: cursor, length: fullRange.location - cursor))
                result.append(
                    NSAttributedString(
                        string: plainText,
                        attributes: [.font: font, .foregroundColor: MemoRichTextFactory.plainTextColor]
                    )
                )
            }

            let boldText = nsLine.substring(with: contentRange)
            result.append(
                NSAttributedString(
                    string: boldText,
                    attributes: [.font: boldFont, .foregroundColor: MemoRichTextFactory.plainTextColor]
                )
            )

            cursor = fullRange.location + fullRange.length
        }

        if cursor < nsLine.length {
            let trailingText = nsLine.substring(from: cursor)
            result.append(
                NSAttributedString(
                    string: trailingText,
                    attributes: [.font: font, .foregroundColor: MemoRichTextFactory.plainTextColor]
                )
            )
        }

        return result
    }

    private static func boldVariant(of font: NSFont) -> NSFont {
        let boldDescriptor = font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(.bold))
        return NSFont(descriptor: boldDescriptor, size: font.pointSize) ?? NSFont.boldSystemFont(ofSize: font.pointSize)
    }
    #endif
}
