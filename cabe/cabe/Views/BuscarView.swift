//  BuscarView.swift
//  cabe

import SwiftUI

enum BuscarAtalho: CaseIterable, Hashable, Identifiable {
    case cartao
    case conta
    case categoria
    case consumo

    var id: Self { self }

    var titulo: String {
        switch self {
        case .cartao: "Cartão"
        case .conta: "Conta"
        case .categoria: "Categoria"
        case .consumo: "Consumo"
        }
    }

    var icone: String {
        switch self {
        case .cartao: "creditcard.fill"
        case .conta: "building.columns.fill"
        case .categoria: "square.grid.2x2.fill"
        case .consumo: "chart.pie.fill"
        }
    }

    var cor: Color {
        switch self {
        case .cartao: .blue
        case .conta: .teal
        case .categoria: .orange
        case .consumo: .purple
        }
    }
}

struct BuscarView<AtalhoDestino: View>: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = BuscarViewModel()
    @StateObject var vmLancamentos: LancamentoListViewModel
    @Binding var searchText: String
    @State private var lancamentoSelecionado: LancamentoModel?
    @State private var atalhoSelecionado: BuscarAtalho?
   
    let destinoDoAtalho: (BuscarAtalho) -> AtalhoDestino

    init(
        vmLancamentos: LancamentoListViewModel,
        searchText: Binding<String>,
        @ViewBuilder destinoDoAtalho: @escaping (BuscarAtalho) -> AtalhoDestino
    ) {
        _vmLancamentos = StateObject(wrappedValue: vmLancamentos)
        _searchText = searchText
        self.destinoDoAtalho = destinoDoAtalho
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                Section {
                    if searchText.isEmpty {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            ForEach(BuscarAtalho.allCases) { atalho in
                                Button {
                                    atalhoSelecionado = atalho
                                } label: {
                                    BuscarAtalhoCard(atalho: atalho)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)

                Section {
                    ForEach(vm.resultados) { lancamento in
                        HStack {
                            LancamentoRow(
                                lancamento: lancamento,
                                mostrarPagamento: false,
                                mostrarVencimento: true
                            )
                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                        .listRowInsets(
                            EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            lancamentoSelecionado = lancamento
                        }
                    }
                } header: {
                    if !vm.resultados.isEmpty {
                        HStack {
                            Text("Resultados")
                            Spacer()
                            Text("\(vm.resultados.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .refreshable {
                vm.onTextoChange(searchText)
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.immediately)
            .scrollContentBackground(.hidden)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay {
            if vm.carregando {
                ProgressView()
            } else if vm.buscou && vm.resultados.isEmpty {
                Text("Nenhum Resultado")
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("Buscar")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Descrição ou Anotação")
        .onChange(of: searchText) { novoValor in
            vm.onTextoChange(novoValor)
        }
        .onAppear {
            vm.recarregarSeNecessario(texto: searchText)
        }
        .sheet(item: $lancamentoSelecionado) { lancamento in
            NavigationStack {
                LancamentoDetalheView(
                    lancamento: lancamento,
                    vmLancamentos: vmLancamentos,
                    isModal: true
                )
            }
        }
        .sheet(item: $atalhoSelecionado) { atalho in
            BuscarAtalhoDestinoSheet(
                titulo: atalho.titulo,
                destino: destinoDoAtalho(atalho)
            )
        }
    }
}

private struct BuscarAtalhoDestinoSheet<Destino: View>: View {
    @Environment(\.dismiss) private var dismiss

    let titulo: String
    let destino: Destino

    var body: some View {
        NavigationStack {
            destino
                .navigationTitle(titulo)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Fechar") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

private struct BuscarAtalhoCard: View {
    let atalho: BuscarAtalho

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: atalho.icone)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline) {
                Text(atalho.titulo)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        atalho.cor.opacity(0.65),
                        atalho.cor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.25), location: 0),
                        .init(color: Color.white.opacity(0.10), location: 0.25),
                        .init(color: .clear, location: 0.6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .blendMode(.softLight)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
