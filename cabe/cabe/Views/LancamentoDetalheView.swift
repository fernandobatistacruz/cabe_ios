//
//  LancamentoDetalheView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 03/01/26.
//

import SwiftUI
import Combine


struct LancamentoDetalheView: View {

    private let repository: LancamentoRepository
    @State private var mostrarEdicao = false
    @StateObject private var vm: LancamentoDetalheViewModel

    init(lancamento: LancamentoModel, repository: LancamentoRepository) {
        self.repository = repository

        _vm = StateObject(
            wrappedValue: LancamentoDetalheViewModel(
                id: lancamento.id ?? 0,
                uuid: lancamento.uuid,
                repository: repository
            )
        )
    }

    var body: some View {
        if let lancamento = vm.lancamento {

            Form {
                Section {
                    HStack(spacing: 10) {

                        Image(
                            systemName: lancamento.transferencia
                            ? "arrow.left.arrow.right"
                            : (lancamento.categoria?.getIcone().systemName ?? "questionmark")
                        )
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(
                            lancamento.transferencia
                            ? (lancamento.tipo == Tipo.despesa.rawValue ? .red : .green)
                            : (lancamento.categoria?.getCor().cor ?? .primary)
                        )

                        VStack(alignment: .leading) {
                            Text(lancamento.descricao)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .font(.title2.bold())

                            Text(
                                lancamento.transferencia
                                ? (lancamento.tipo == Tipo.despesa.rawValue ? "Saída" : "Entrada")
                                : (
                                    lancamento.categoria?.isSub == true
                                    ? lancamento.categoria?.nomeSubcategoria ?? ""
                                    : lancamento.categoria?.nome ?? ""
                                )
                            )
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(
                            lancamento.valorComSinal,
                            format: .currency(code: lancamento.currencyCode)
                        )
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }

                Section(header: Text("Geral")) {
                    HStack {
                        Text("Situação")
                        Spacer()
                        Text(lancamento.pago ? "Pago" : "Não Pago")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Repete")
                        Spacer()
                        Text(lancamento.tipoRecorrente.titulo)
                            .foregroundColor(.secondary)
                    }

                    if lancamento.recorrente == TipoRecorrente.parcelado.rawValue {
                        HStack {
                            Text("Parcela")
                            Spacer()
                            Text(lancamento.parcelaMes)
                                .foregroundColor(.secondary)
                        }
                    }

                    if lancamento.cartao != nil {
                        HStack {
                            Text("Pago com Cartão")
                            Spacer()
                            Text(lancamento.cartao?.nome ?? "")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Pago com Conta")
                            Spacer()
                            Text(lancamento.conta?.nome ?? "")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Vencimento")
                            Spacer()
                            Text(lancamento.dataVencimentoFormatada)
                                .foregroundColor(.secondary)
                        }
                    }

                    if lancamento.dividido {
                        HStack {
                            Text("Dividido")
                            Spacer()
                            Text(
                                lancamento.valorComSinal / 2,
                                format: .currency(code: lancamento.currencyCode)
                            )
                            .foregroundColor(.secondary)
                        }
                    }
                }

                if lancamento.cartao == nil {
                    Section(header: Text("Cartão de Crédito")) {
                        HStack {
                            Text("Fatura")
                            Spacer()
                            Text(lancamento.dataFaturaFormatada)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Data da Compra")
                            Spacer()
                            Text(lancamento.dataCompraFormatada)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Anotação")) {
                    Text(lancamento.anotacao)
                        .multilineTextAlignment(.leading)
                }
            }
            .navigationTitle("Detalhar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                if !lancamento.transferencia {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "pencil")
                            .onTapGesture {
                                mostrarEdicao = true
                            }
                    }
                }
            }
            .sheet(isPresented: $mostrarEdicao) {
                EditarLancamentoView(
                    lancamento: lancamento,
                    repository: repository
                )
            }

        } else {
            EmptyStateView(
                title: "Lançamento removido",
                systemImage: "trash",
                description: "Este lançamento não existe mais."
            )
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3.bold())

            if let description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
