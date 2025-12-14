//
//  CartaoListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/12/25.
//


import SwiftUI

struct CartoesView: View {

    @StateObject private var viewModel = CartaoListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Carregando cartões...")
                } else if viewModel.cartoes.isEmpty {
                    ContentUnavailableView(
                        "Nenhum cartão",
                        systemImage: "creditcard",
                        description: Text("Não há cartões cadastrados")
                    )
                } else {
                    List(viewModel.cartoes, id: \.uuid) { cartao in
                        CartaoRowView(cartao: cartao)
                    }
                }
            }
            .navigationTitle("Cartões")
            .toolbar(.hidden, for: .tabBar)
        }
        .onAppear {
            viewModel.carregar()
        }
    }
}

#Preview {
    CartoesView().environmentObject(ThemeManager())
}

struct CartaoRowView: View {

    let cartao: CartaoModel

    var body: some View {
        HStack() {
            Image(systemName: "creditcard")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading) {
                Text(cartao.nome)
                    .font(.headline)
                Text("Vencimento: dia \(cartao.vencimento)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

