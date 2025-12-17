import SwiftUI

struct TabMenuView: View {
    var body: some View {
        TabView {
            InicioView()
                .tabItem {
                    Label("Início", systemImage: "doc.text.image")
                }

            LancamentosView()
                .tabItem {
                    Label("Lançamentos", systemImage: "square.stack.fill")
                }

            ResumoView()
                .tabItem {
                    Label("Resumo", systemImage: "chart.bar.xaxis")
                }
            
            AjustesView()
                .tabItem {
                    Label("Ajustes", systemImage: "gear")
                }
        }
    }
}

#Preview {
    TabMenuView()
}

