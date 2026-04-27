import SwiftUI

#if os(macOS)
import AppKit

/// 自定义滚动条样式：更细、颜色更浅
class ThinScroller: NSScroller {
    override class var isCompatibleWithOverlayScrollers: Bool {
        return true
    }
    
    override func drawKnob() {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        
        let knobRect = self.rect(for: .knob)
        
        // 只有当内容可滚动时才绘制
        if knobRect.height == 0 || knobRect.height == self.bounds.height {
            ctx.restoreGState()
            return
        }
        
        // 设置更细的宽度 (从 3.0 调整为 5.0)
        let desiredWidth: CGFloat = 5.0
        // 居中显示
        let xOffset = (bounds.width - desiredWidth) / 2
        
        // 计算新的绘制区域
        // 注意：knobRect 的 y 和 height 是由父类计算好的，我们只修改 x 和 width
        let newRect = CGRect(
            x: xOffset,
            y: knobRect.origin.y,
            width: desiredWidth,
            height: knobRect.height
        )
        
        let path = CGPath(roundedRect: newRect, cornerWidth: desiredWidth / 2, cornerHeight: desiredWidth / 2, transform: nil)
        ctx.addPath(path)
        
        // 设置颜色：浅灰色
        // 系统默认可能是半透明黑色，我们调得更浅一点
        NSColor.black.withAlphaComponent(0.15).setFill()
        ctx.fillPath()
        
        ctx.restoreGState()
    }
    
    // 不绘制背景槽，保持极简
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // Do nothing
    }
}

/// 用于查找并替换 NSScrollView 的 Scroller 的辅助视图
struct ScrollbarCustomizer: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = ScrollbarHelperView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    /// 内部辅助视图，利用生命周期尽早替换 Scrollbar
    private class ScrollbarHelperView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            customizeScrollbar()
        }
        
        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            customizeScrollbar()
        }
        
        private func customizeScrollbar() {
            guard let scrollView = self.enclosingScrollView else { return }
            
            // 如果还没有替换，则进行替换
            if !(scrollView.verticalScroller is ThinScroller) {
                let newScroller = ThinScroller()
                scrollView.verticalScroller = newScroller
                // 确保 Scroller 处于 Overlay 模式（如果需要）
                scrollView.scrollerStyle = .overlay
            }
        }
    }
}

extension View {
    /// 应用自定义的浅色细滚动条
    func thinScrollbar() -> some View {
        self.background(ScrollbarCustomizer())
    }
}
#endif
