import Foundation
import SwiftUI

struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    
    let style: UIActivityIndicatorView.Style
    let hideWhenNotAnimating: Bool

    public init(
        isAnimating: Binding<Bool>,
        style: UIActivityIndicatorView.Style,
        hideWhenNotAnimating: Bool = true
    ) {
        self._isAnimating = isAnimating
        self.style = style
        self.hideWhenNotAnimating = hideWhenNotAnimating
    }
    
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
