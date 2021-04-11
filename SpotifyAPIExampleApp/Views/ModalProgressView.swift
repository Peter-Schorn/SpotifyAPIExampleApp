import Foundation
import SwiftUI

struct ModalProgressView: ViewModifier {

    @Environment(\.colorScheme) var colorScheme

    let message: String

    init(message: String, isPresented: Binding<Bool>) {
        self.message = message
        self._isPresented = Binding(
            get: {
                withAnimation {
                    isPresented.wrappedValue
                }
            },
            set: { newValue in
                withAnimation {
                    isPresented.wrappedValue = newValue
                }
            }
        )
    }

    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
            
        ZStack {
            content
                .disabled(isPresented)
                .blur(radius: isPresented ? 2 : 0)
            
            if isPresented {
                Color.black
                    .opacity(isPresented ? 0.25 : 0)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 40) {
                    ProgressView()
                        .font(.title)
                        .scaleEffect(1.5, anchor: .center)
                    Text(message)
                        .font(.headline)
                }
                .frame(width: 250, height: 170)
                .background(
                    Rectangle()
                        .fill(BackgroundStyle())
                        .opacity(0.75)
                )
                .cornerRadius(20)
                .transition(
                    AnyTransition.scale(scale: 1.2)
                        .combined(with: .opacity)
                )
            }
        }

    }

}

extension View {
    
    func modalProgressView(
        message: String,
        isPresented: Binding<Bool>
    ) -> some View {
        self.modifier(
            ModalProgressView(
                message: message,
                isPresented: isPresented
            )
        )
    }
    
}

struct ModalProgressView_Previews: PreviewProvider {
    
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            List(0..<10) { i in
                Text("item \(i)")
            }
            .modalProgressView(
                message: "Authenticating",
                isPresented: .constant(true)
            )
            .preferredColorScheme(colorScheme)
            
        }
        
    }

}
