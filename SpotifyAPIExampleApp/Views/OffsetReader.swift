import SwiftUI

struct ScrollViewOffset<Content: View>: View {
    
    let frameCoordinateSpace = "frameLayer"

    let onOffsetChange: (CGFloat) -> Void
    let content: () -> Content
    
    init(
        onOffsetChange: @escaping (CGFloat) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.onOffsetChange = onOffsetChange
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            offsetReader
            content()
                .padding(.top, -8)
        }
        .coordinateSpace(name: frameCoordinateSpace)
        .onPreferenceChange(
            OffsetPreferenceKey.self,
            perform: onOffsetChange
        )
    }
    
    var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: proxy.frame(in: .named(frameCoordinateSpace)).minY
                )
        }
        .frame(height: 0)
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}
