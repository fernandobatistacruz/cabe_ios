//
//  LancamentoListView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import SwiftUI

struct LancamentoListView: View {
    
    @State private var searchText = ""
    @State private var mostrarNovoLancamento = false
    @State private var lancamentoParaExcluir: LancamentoModel?
    @StateObject private var viewModel: LancamentoListViewModel
    @State private var showCalendar = false
    @State private var mostrarDialogExclusao = false
    
    private var selectedDate: Date {
        Calendar.current.date(
            from: DateComponents(
                year: viewModel.anoAtual,
                month: viewModel.mesAtual,
                day: 1
            )
        ) ?? Date()
    }
    
    init() {
        let repository = LancamentoRepository()
        let mesAtual = Calendar.current.component(.month, from: Date())
        let anoAtual = Calendar.current.component(.year, from: Date())
        
        _viewModel = StateObject(
            wrappedValue: LancamentoListViewModel(
                repository: repository,
                mes: mesAtual,
                ano: anoAtual
            )
        )
    }
    
    var lancamentosFiltrados: [LancamentoModel] {
        let texto = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { return viewModel.lancamentos }
        
        return viewModel.lancamentos.filter {
            $0.descricao.localizedCaseInsensitiveContains(texto)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(lancamentosAgrupados, id: \.date) { section in
                        
                        Section {
                            ForEach(section.items) { item in
                                switch item {
                                case .simples(let lancamento):
                                    NavigationLink {
                                        LancamentoDetalheView(lancamento: lancamento)
                                    } label: {
                                        LancamentoRow(lancamento: lancamento, mostrarPagamento: true, mostrarValores: true)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    lancamentoParaExcluir = lancamento
                                                    mostrarDialogExclusao = true
                                                } label: {
                                                    Label("Excluir", systemImage: "trash")
                                                }
                                            }
                                            .swipeActions(edge: .leading,allowsFullSwipe: false) {
                                                Button() {
                                                    Task{
                                                        await viewModel.togglePago([lancamento])
                                                    }
                                                } label: {
                                                    Label(lancamento.pago ? String(localized: "Não Pago") : String(localized: "Pago"), systemImage: lancamento.pago ? "checklist.unchecked" : "checklist")
                                                }.tint(.accentColor)
                                            }
                                    }
                                    
                                case .cartaoAgrupado(let cartao, let total, let lancamentos):
                                    NavigationLink {
                                        CartaoFaturaView(
                                            cartao: cartao,
                                            lancamentos: lancamentos,
                                            total: total,
                                            vencimento: section.date
                                        )
                                    } label: {
                                        LancamentoCartaoRow(
                                            cartao: cartao,
                                            lancamentos: lancamentos,
                                            total: total
                                        )
                                        .swipeActions(edge: .leading,allowsFullSwipe: false) {
                                            Button() {
                                                Task{
                                                    await viewModel.togglePago(lancamentos)
                                                }
                                            } label: {
                                                var temPendentes: Bool {
                                                    lancamentos.contains { !$0.pago }
                                                }
                                                Label(
                                                    temPendentes ? String(
                                                        localized: "Pago"
                                                    ): String(localized: "Não Pago"),
                                                    systemImage: temPendentes ?
                                                    "checklist.checked" : "checklist.unchecked"
                                                )
                                            }.tint(.accentColor)
                                        }
                                    }
                                }
                            }
                            .listRowInsets(
                                EdgeInsets(
                                    top: 8,
                                    leading: 16,
                                    bottom: 8,
                                    trailing: 16
                                )
                            )
                        } header: {
                            Text(section.date, format: .dateTime.day().month(.wide))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            mostrarNovoLancamento = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(
                Text(selectedDate, format: .dateTime.month(.wide))
            )
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Buscar")
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCalendar = true
                    } label: {
                        //Image(systemName: "chevron.left")
                        Text(selectedDate, format: .dateTime.year())
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        print("Mais ações")
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .confirmationDialog(
                "Excluir lançamento?",
                isPresented: $mostrarDialogExclusao,
                titleVisibility: .visible
            ) {
                if let lancamento = lancamentoParaExcluir {

                    if lancamento.tipoRecorrente == .nunca {
                        Button("Confirmar exclusão", role: .destructive) {
                            Task { await excluirTodos(lancamento) }
                        }
                    } else {
                        Button("Excluir somente este", role: .destructive) {
                            Task { await excluirSomenteEste(lancamento) }
                        }

                        Button("Excluir este e os próximos", role: .destructive) {
                            Task { await excluirEsteEProximos(lancamento) }
                        }

                        Button("Excluir todos", role: .destructive) {
                            Task { await excluirTodos(lancamento) }
                        }
                    }
                }
            }
            message: {
                Text("Essa ação não poderá ser desfeita.")
            }

            .sheet(isPresented: $mostrarNovoLancamento) {
                NovoLancamentoView()
            }
            .sheet(isPresented: $showCalendar) {
                CalendarioZoomView(
                    dataInicial: selectedDate,
                    onConfirm: { dataSelecionada in
                        viewModel.selecionar(data: dataSelecionada)
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func excluirSomenteEste(_ lancamento: LancamentoModel) async {
        await viewModel.removerSomenteEste(lancamento)
    }

    private func excluirEsteEProximos(_ lancamento: LancamentoModel) async {
        await viewModel.removerEsteEProximos(lancamento)
    }
    
    private func excluirTodos(_ lancamento: LancamentoModel) async {
        await viewModel.removerTodosRecorrentes(lancamento)
    }

    
    var lancamentosAgrupados: [(date: Date, items: [LancamentoItem])] {
        
        let porData = Dictionary(grouping: lancamentosFiltrados) {
            Calendar.current.startOfDay(for: $0.dataAgrupamento)
        }
        
        let resultado = porData.map { (date, lancamentosDoDia) in
            
            let itensSimples = lancamentosDoDia
                .filter { $0.cartao == nil }
                .map { LancamentoItem.simples($0) }
            
            let comCartao = lancamentosDoDia.filter { $0.cartao != nil }
            
            let porCartao = Dictionary(grouping: comCartao) {
                $0.cartao!.id!
            }
            
            let itensCartao = porCartao.map { (_, lancamentos) in
                let cartao = lancamentos.first!.cartao!
                
                let total = lancamentos.reduce(.zero) { $0 + $1.valorComSinal }
                
                return LancamentoItem.cartaoAgrupado(
                    cartao: cartao,
                    total: total,
                    lancamentos: lancamentos
                )
            }
            
            return (date: date, items: itensSimples + itensCartao)
        }
        
        return resultado.sorted { $0.date > $1.date }
    }
    
    private func excluir(_ lancamento: LancamentoModel) async {
        await viewModel.remover(id: lancamento.id ?? 0, uuid: lancamento.uuid)
    }
}

struct LancamentoCartaoRow: View {

    let cartao: CartaoModel
    let lancamentos: [LancamentoModel]
    let total: Decimal
   
    private var temPendentes: Bool {
        lancamentos.contains { !$0.pago }
    }

    var body: some View {
        HStack(spacing: 12) {
        
            Circle()
                .fill(temPendentes ? .accentColor : Color.clear)
                .frame(width: 12, height: 12)
          
            Image(cartao.operadoraEnum.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        
            VStack(alignment: .leading, spacing: 2) {
                Text(cartao.nome)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text("Fatura")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(
                total,
                format: .currency(code: cartao.conta?.currencyCode ?? "BRL")
            )
            .foregroundColor(.secondary)
        }
    }
}

struct LancamentoRow: View {
    let lancamento: LancamentoModel   
    let mostrarPagamento: Bool
    let mostrarValores: Bool

    var body: some View {
        HStack(spacing: 12) {
            if(mostrarPagamento) {
                Circle()
                    .fill(lancamento.pago ? Color.clear : .accentColor)
                    .frame(width: 12, height: 12)
            }
            Image(systemName: lancamento.categoria?.getIcone().systemName ?? "")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(lancamento.categoria?.getCor().cor)
            
            VStack(alignment: .leading) {
                Text(lancamento.descricao)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(lancamento.categoria?.nome ?? "")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()
            
            if(mostrarValores) {
                Text(
                    lancamento.valorComSinal,
                    format: .currency(
                        code: lancamento.cartao?.conta?.currencyCode ?? "BRL"
                    )
                )
                .foregroundColor(.secondary)
            } else {
                Text("•••")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DialogoExclusaoLancamento: View {

    let lancamento: LancamentoModel?
    let removerSomenteEste: (LancamentoModel) -> Void
    let removerEsteEProximos: (LancamentoModel) -> Void
    let removerTodos: (LancamentoModel) -> Void

    var body: some View {

        if let lancamento {

            if lancamento.tipoRecorrente == .nunca {

                Button("Confirmar exclusão", role: .destructive) {
                    removerTodos(lancamento)
                }

            } else {

                Button("Remover somente este", role: .destructive) {
                    removerSomenteEste(lancamento)
                }

                Button("Remover este e os próximos", role: .destructive) {
                    removerEsteEProximos(lancamento)
                }

                Button("Remover todos", role: .destructive) {
                    removerTodos(lancamento)
                }
            }
        }
        
        Button("Cancelar", role: .cancel) { }
    }
}




