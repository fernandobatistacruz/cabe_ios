import SwiftUI

struct TabMenuView: View {
    var body: some View {
        TabView {
            //TODO: Retirar o NavigationStack das View e adicionar no TabView
            InicioView()
                .tabItem {
                    Label("Início", systemImage: "doc.text.image")
                }

            LancamentoListView()
                .tabItem {
                    Label("Lançamentos", systemImage: "square.stack.fill")
                }

            NavigationStack{
                ResumoAnualView()
            }.tabItem {
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

