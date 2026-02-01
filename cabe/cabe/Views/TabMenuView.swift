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
            TabView (selection: $deepLinkManager.selectedTab) {
                Tab("Início", systemImage: "text.rectangle.page.fill", value: TabItem.inicio) {
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
                }
                Tab("Lançamentos", systemImage: "square.stack.fill", value: TabItem.lancamentos) {
                    NavigationStack {
                        LancamentoListView(viewModel: vmLancamentos)
                    }
                }
                Tab("Resumo", systemImage: "chart.bar.xaxis", value: TabItem.resumo) {
                    NavigationStack {
                        ResumoAnualView()
                    }
                }
                Tab("Ajustes", systemImage: "gear", value: TabItem.ajustes) {
                    NavigationStack {
                        AjustesView()
                    }
                }
                Tab(value: TabItem.buscar, role: .search) {
                    NavigationStack {
                        BuscarView(
                            vmLancamentos: vmLancamentos,
                            searchText: $searchText,                           
                        )
                    }
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
