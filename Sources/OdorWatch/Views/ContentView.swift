import SwiftUI

struct ContentView: View {
    @StateObject private var vm = OdorViewModel()

    var body: some View {
        HomeView(vm: vm)
            .preferredColorScheme(nil)
    }
}
