//
//  NewTabView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 29/01/26.
//

import SwiftUI

enum TabItem: Hashable {
    case inicio
    case lancamentos
    case resumo
    case ajustes
    case buscar
}

struct TabMenuView: View {
    @State private var searchText = ""
    @EnvironmentObject var deepLinkManager: DeepLinkManager
        
    @StateObject private var vmLancamentos =
        LancamentoListViewModel(
            repository: LancamentoRepository(),
            mes: Calendar.current.component(.month, from: Date()),
            ano: Calendar.current.component(.year, from: Date())
        )
    
    @StateObject private var vmContas = ContaListViewModel(repository: ContaRepository())
    
    var body: some View {
        if #available(iOS 18.0, *) {
            TabView {
                Tab("Início", systemImage: "text.rectangle.page.fill") {
                    NavigationStack(path: $deepLinkManager.path) {
                        InicioView(
                            vmLancamentos: vmLancamentos,
                            vmContas: vmContas
                        )
                            .navigationDestination(for: DeepLink.self) { destination in
                                switch destination {
                                case .notificacoes:
                                    NotificacoesView(vmNotificacao: vmLancamentos.notificacaoVM,
                                                     vmLancamentos: vmLancamentos)
                                }
                            }
                    }
                    .tag(TabItem.inicio)
                }
                Tab("Lançamentos", systemImage: "square.stack.fill") {
                    NavigationStack {
                        LancamentoListView(viewModel: vmLancamentos)
                    }
                    .tag(TabItem.lancamentos)
                }
                Tab("Resumo", systemImage: "chart.bar.xaxis") {
                    NavigationStack {
                        ResumoAnualView()
                    }
                    .tag(TabItem.resumo)
                }
                Tab("Ajustes", systemImage: "gear") {
                    NavigationStack {
                        AjustesView()
                    }
                    .tag(TabItem.ajustes)
                }
                Tab(role: .search) {
                    NavigationStack {
                        BuscarView(
                            vmLancamentos: vmLancamentos,
                            searchText: $searchText,                           
                        )
                    }
                    .tag(TabItem.buscar)
                }
            }
        } else {
            TabView (selection: $deepLinkManager.selectedTab) {
                NavigationStack(path: $deepLinkManager.path) {
                    InicioView(vmLancamentos: vmLancamentos, vmContas: vmContas)
                        .navigationDestination(for: DeepLink.self) { destination in
                            switch destination {
                            case .notificacoes:
                                NotificacoesView(vmNotificacao: vmLancamentos.notificacaoVM,
                                                 vmLancamentos: vmLancamentos)
                            }
                        }
                }
                .tabItem {
                    Label("Início", systemImage: "text.rectangle.page.fill")
                }
                .tag(TabItem.inicio)
                
                NavigationStack {
                    LancamentoListView(viewModel: vmLancamentos)
                }
                .tabItem {
                    Label("Lançamentos", systemImage: "square.stack.fill")
                }
                .tag(TabItem.lancamentos)

                NavigationStack {
                    ResumoAnualView()
                }
                .tabItem {
                    Label("Resumo", systemImage: "chart.bar.xaxis")
                }
                .tag(TabItem.resumo)

                NavigationStack {
                    AjustesView()
                }
                .tabItem {
                    Label("Ajustes", systemImage: "gear")
                }
                .tag(TabItem.ajustes)
                
                NavigationStack {
                    BuscarView(
                        vmLancamentos: vmLancamentos,
                        searchText: $searchText,
                    )
                }
                .searchable(text: $searchText)
                .tabItem {
                    Label("Buscar", systemImage: "magnifyingglass")
                }
                .tag(TabItem.buscar)
            }
        }
    }
}
