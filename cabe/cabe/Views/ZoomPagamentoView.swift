//
//  ZoomPagamentoView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/12/25.
//

/*
import SwiftUI

struct ZoomPagamentoView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ZoomPagamentoViewModel()

    let onSelecionar: (MeioPagamento) -> Void

    var body: some View {
        List {

            if !viewModel.cartoes.isEmpty {
                Section("Cartões") {
                    ForEach(viewModel.cartoes) { cartao in
                        Button {
                            onSelecionar(.cartao(cartao))
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(cartao.nome)
                                        .foregroundColor(.primary)
                                    Text("Cartão")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                }
            }

            if !viewModel.contas.isEmpty {
                Section("Contas") {
                    ForEach(viewModel.contas) { conta in
                        Button {
                            onSelecionar(.conta(conta))
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(conta.nome)
                                        .foregroundColor(.primary)
                                    Text("Conta")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                }
            }
        }
        .navigationTitle("Pagamento")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.carregarDados()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

*/

import SwiftUI

struct ZoomPagamentoView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ZoomPagamentoViewModel()

    @Binding var selecionado: MeioPagamento?

    var body: some View {
        List {

            // MARK: - Cartões
            if !viewModel.cartoes.isEmpty {
                Section("Cartões") {
                    ForEach(viewModel.cartoes) { cartao in
                        let meio = MeioPagamento.cartao(cartao)

                        Button {
                            selecionado = meio
                            dismiss()
                        } label: {
                            PagamentoRowView(
                                titulo: cartao.nome,
                                subtitulo: "Cartão",
                                leadingImage: Image(cartao.operadoraEnum.imageName),
                                isSelected: meio == selecionado
                            )
                        }
                        .listRowInsets(
                            EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                        )
                    }
                }
            }

            // MARK: - Contas
            if !viewModel.contas.isEmpty {
                Section("Contas") {
                    ForEach(viewModel.contas) { conta in
                        let meio = MeioPagamento.conta(conta)

                        Button {
                            selecionado = meio
                            dismiss()
                        } label: {
                            PagamentoRowView(
                                titulo: conta.nome,
                                subtitulo: "Conta",
                                leadingImage: Image(systemName: "building.columns"),
                                isSelected: meio == selecionado
                            )
                        }
                        .listRowInsets(
                            EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Pagamento")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.carregarDados()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}


struct PagamentoRowView: View {
    
    let titulo: String
    let subtitulo: String
    let leadingImage: Image?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {

            if let leadingImage {
                leadingImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .foregroundColor(.primary)
                Text(subtitulo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
    }
}
