import SwiftUI

enum Tab: Hashable {
    case inicio
    case lancamentos
    case resumo
    case ajustes
}

struct TabMenuView: View {
    
    @EnvironmentObject var deepLinkManager: DeepLinkManager
        
    @StateObject private var vmLancamentos =
        LancamentoListViewModel(
            repository: LancamentoRepository(),
            mes: Calendar.current.component(.month, from: Date()),
            ano: Calendar.current.component(.year, from: Date())
        )
    
    var body: some View {
        TabView (selection: $deepLinkManager.selectedTab) {
            NavigationStack(path: $deepLinkManager.path) {
                InicioView(vmLancamentos: vmLancamentos)
                    .navigationDestination(for: DeepLink.self) { destination in
                        switch destination {
                        case .notificacoes:
                            NotificacoesView(
                                vmLancaentos: vmLancamentos,
                                vmNotificacao: vmLancamentos.notificacaoVM
                            )
                        }
                    }
            }
            .tabItem {
                Label("Início", systemImage: "text.rectangle.page.fill")
            }
            .tag(Tab.inicio)
            
            NavigationStack {
                LancamentoListView(viewModel: vmLancamentos)
            }
            .tabItem {
                Label("Lançamentos", systemImage: "square.stack.fill")
            }
            .tag(Tab.lancamentos)

            NavigationStack {
                ResumoAnualView()
            }
            .tabItem {
                Label("Resumo", systemImage: "chart.bar.xaxis")
            }
            .tag(Tab.resumo)

            NavigationStack {
                AjustesView()
            }
            .tabItem {
                Label("Ajustes", systemImage: "gear")
            }
            .tag(Tab.ajustes)
        }
    }
}
