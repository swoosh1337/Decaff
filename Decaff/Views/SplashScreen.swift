import SwiftUI

struct SplashScreen: View {
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        ZStack {
            Color("F5E6D3") // Beige background color
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundColor(Color("4A3728")) // Dark brown color
                    .scaleEffect(size)
                    .opacity(opacity)
                
                Text("Decaff")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Color("4A3728"))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                self.size = 1.0
                self.opacity = 1.0
            }
        }
    }
}

#if DEBUG
struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            SplashScreen()
                .previewDisplayName("Light Mode")
            
            // Dark mode preview
            SplashScreen()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // Different device sizes
            SplashScreen()
                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                .previewDisplayName("iPhone 15 Pro")
            
            SplashScreen()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
                .previewDisplayName("iPhone SE")
            
            // Landscape preview
            SplashScreen()
                .previewInterfaceOrientation(.landscapeLeft)
                .previewDisplayName("Landscape")
        }
    }
}
#endif
