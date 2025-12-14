//
//  ContentView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 12/12/25.
//

import SwiftUI

struct TabMenuView: View {
    var body: some View {
        TabView {
            InicioView()
                .tabItem {
                    Label("Início", systemImage: "text.rectangle.page")
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
