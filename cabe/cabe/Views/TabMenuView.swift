import SwiftUI

struct TabMenuView: View {
    
    @EnvironmentObject var deepLinkManager: DeepLinkManager
        
    @StateObject private var vmLancamentos =
        LancamentoListViewModel(
            repository: LancamentoRepository(),
            mes: Calendar.current.component(.month, from: Date()),
            ano: Calendar.current.component(.year, from: Date())
        )
    
    var body: some View {
        TabView {
          
            NavigationStack(path: $deepLinkManager.path) {
                            InicioView(vmLancamentos: vmLancamentos) // ⬅️ usa o mesmo VM
                                .navigationDestination(for: DeepLink.self) { destination in
                                    switch destination {
                                    case .notificacoes:
                                        NotificacoesView(
                                            vm: vmLancamentos.notificacaoVM // ✅ O MESMO
                                        )
                                    }
                                }
                        }
            .tabItem {
                Label("Início", systemImage: "square.stack.fill")
            }

            /*
            NavigationStack {
                InicioView()
                    .navigationDestination(for: DeepLink.self) { destination in
                        switch destination {
                        case .notificacoes:
                            NotificacoesView(
                                vm: NotificacaoViewModel()
                            )
                        }
                    }
            }
            .tabItem {
                Label("Início", systemImage: "square.stack.fill")
            }
             */
            
            NavigationStack {
                LancamentoListView()
            }
            .tabItem {
                Label("Lançamentos", systemImage: "square.stack.fill")
            }

            NavigationStack {
                ResumoAnualView()
            }
            .tabItem {
                Label("Resumo", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                AjustesView()
            }
            .tabItem {
                Label("Ajustes", systemImage: "gear")
            }
        }
        .environmentObject(deepLinkManager)
    }
}
