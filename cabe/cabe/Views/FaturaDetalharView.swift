import SwiftUI

struct FaturaDetalharView: View {
    @ObservedObject var viewModel: LancamentoListViewModel
    let cartao: CartaoModel
    let total: Decimal
    let vencimento: Date

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var shareItem: ShareItem?
    @State private var lancamentoParaExcluir: LancamentoModel?
    @State private var mostrarDialogExclusao = false
    @State private var ordemData: OrdemData = .decrescente
    @State private var filtroSelecionado: FiltroLancamentoFatura = .todos
    @Environment(\.dismiss) private var dismiss
    @State private var mostrarNovaDespesa = false
    
    var lancamentos: [LancamentoModel] {
        viewModel.lancamentos.filter {
            $0.cartaoUuid == cartao.uuid
        }
    }
    
    

    // 🔹 Estados da conferência
    @State private var modoConferencia = false
    @State private var lancamentosConferidos: Set<LancamentoModel.ID> = []

    var filtroLancamentos: [LancamentoModel] {
        var resultado = searchText.isEmpty
        ? lancamentos
        : lancamentos.filter {
            $0.descricao.localizedCaseInsensitiveContains(searchText)
        }
        
        switch filtroSelecionado {
        case .todos:
            break
            
        case .recorrentes:
            resultado = resultado.filter {
                $0.tipoRecorrente == .semanal ||
                $0.tipoRecorrente == .quinzenal ||
                $0.tipoRecorrente == .mensal
            }
            
        case .parcelados:
            resultado = resultado.filter {
                $0.tipoRecorrente == .parcelado
            }
            
        case .divididos:
            resultado = resultado.filter {
                $0.dividido == true
            }
        }
        
        resultado.sort {
            guard let d0 = $0.dataCompra,
                  let d1 = $1.dataCompra else {
                return false
            }
            
            return ordemData == .crescente
            ? d0 < d1
            : d0 > d1
        }

        return resultado
    }
    
    private var filtroAtivo: Bool {
        ordemData != .decrescente || filtroSelecionado != .todos
    }
    
    // 🔹 Total dinâmico da conferência
    var totalConferido: Decimal {
        lancamentos
            .filter { lancamentosConferidos.contains($0.id) }
            .map(\.valorComSinal)
            .reduce(0, +)
    }
    
    var totalFiltrado: Decimal {
        if filtroSelecionado == .divididos {
            filtroLancamentos
                .map(\.valorParaSaldo)
                .reduce(0, +)
        } else {
            filtroLancamentos
                .map(\.valorComSinal)
                .reduce(0, +)
        }
    }

    var body: some View {
        List {
            // 🔹 Card do cartão
            HStack(spacing: 10) {
                Image(cartao.operadoraEnum.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)

                VStack(alignment: .leading, spacing: 4) {
                    Text(cartao.nome)
                        .font(.title2.bold())
                        .lineLimit(2)
                        .truncationMode(.tail)

                    Text(vencimento.formatted(date: .numeric, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading) // 🔑 ocupa o espaço flexível

                Text(
                    modoConferencia ? totalConferido : filtroSelecionado != .todos ? totalFiltrado : total,
                    format: .currency(
                        code: lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode
                    )
                )
                .font(.title3.bold())
                .foregroundStyle(
                    modoConferencia ? Color.accentColor : .primary
                )
                .fixedSize(horizontal: true, vertical: false) // 🔒 nunca trunca
            }

            if !filtroLancamentos.isEmpty {
                Section("Entries") {
                    ForEach(filtroLancamentos) { lancamento in
                        if modoConferencia {
                            LancamentoConferenciaRow(
                                lancamento: lancamento,
                                selecionado: lancamentosConferidos.contains(lancamento.id)
                            )
                            .onTapGesture {
                                toggleConferencia(lancamento)
                            }
                        } else {
                            NavigationLink {
                                LancamentoDetalheView(
                                    lancamento: lancamento,
                                    vmLancamentos: viewModel
                                )
                            } label: {
                                LancamentoRow(
                                    lancamento: lancamento,
                                    mostrarPagamento: false,
                                    mostrarValores: true,
                                    mostrarData: true
                                )
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    lancamentoParaExcluir = lancamento
                                    mostrarDialogExclusao = true
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listRowInsets(
                        EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Fatura")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Buscar", text: $searchText)
                        .focused($searchFocused)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .clipShape(Capsule())
                
                if !searchText.isEmpty {
                    Spacer()
                    Button {
                        searchText = ""
                        UIApplication.shared.endEditing()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .disabled(searchText.isEmpty)
                }
                if searchText.isEmpty {
                    Spacer()
                    Button {
                        mostrarNovaDespesa = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Section {
                        ForEach(OrdemData.allCases, id: \.self) { ordem in
                            Button {
                                ordemData = ordem
                            } label: {
                                HStack {
                                    Text(ordem.titulo)

                                    Spacer()

                                    if ordemData == ordem {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    Section {
                        ForEach(FiltroLancamentoFatura.allCases) { filtro in
                            Button {
                                filtroSelecionado = filtro
                            } label: {
                                HStack {
                                    Text(filtro.titulo)

                                    Spacer()

                                    if filtroSelecionado == filtro {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: filtroAtivo
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease"
                    )
                    .symbolRenderingMode(filtroAtivo ? .palette : .monochrome)
                    .foregroundStyle(
                        filtroAtivo ? Color.white : Color.primary,
                        Color.accentColor
                    )
                }
                Menu {
                    Button {
                        withAnimation {
                            modoConferencia = true
                            lancamentosConferidos.removeAll()
                        }
                    } label: {
                        Label("Conferência", systemImage: "doc.text.magnifyingglass")
                    }
                    
                    Divider()

                    Button {
                        Task { await exportarCSV() }
                    } label: {
                        if isExporting {
                            ProgressView()
                        } else {
                            Label("Exportar", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting)
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
           
            if modoConferencia {
                ToolbarItem(placement: .topBarLeading) {
                    Button("OK") {
                        withAnimation {
                            modoConferencia = false
                            lancamentosConferidos.removeAll()
                        }
                    }
                }
            }
        }
        .overlay(
            Group {
                if filtroLancamentos.isEmpty {
                    Text("Nenhum Lançamento")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)                    
                }
            }
        )
        .sheet(item: $shareItem) { item in
            ShareSheetView(
                message: "Fatura de \(String(vencimento.formatted(.dateTime.month(.wide).year()))) do cartão \(String(cartao.nome)) extraído do Cabe",
                subject: "Fatura de \(String(vencimento.formatted(.dateTime.month(.wide).year()))) do cartão \(String(cartao.nome)) extraído do Cabe",
                fileURL: item.url
            )
        }
        .sheet(isPresented: $mostrarNovaDespesa) {
            NovoLancamentoView(
                repository: viewModel.repository,
                meioPagamento: MeioPagamento.cartao(cartao)
            )
        }
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    ProgressView().scaleEffect(1.2)
                }
            }
        }
        .confirmationDialog(
            "Excluir Lançamento?",
            isPresented: $mostrarDialogExclusao,
            titleVisibility: .visible
        ) {
            if let lancamento = lancamentoParaExcluir {
                if lancamento.tipoRecorrente == .nunca {
                    Button("Confirmar Exclusão", role: .destructive) {
                        Task { await viewModel.removerTodosRecorrentes(lancamento) }
                    }
                } else {
                    Button("Excluir Somente Este", role: .destructive) {
                        Task { await viewModel.removerSomenteEste(lancamento) }
                    }
                    
                    Button("Excluir Este e os Próximos", role: .destructive) {
                        Task { await viewModel.removerEsteEProximos(lancamento) }
                    }
                    
                    Button("Excluir Todos", role: .destructive) {
                        Task { await viewModel.removerTodosRecorrentes(lancamento) }
                    }
                }
            }
        }
        message: {
            Text("Essa ação não poderá ser desfeita.")
        }
    }
  
    private func toggleConferencia(_ lancamento: LancamentoModel) {
        if lancamentosConferidos.contains(lancamento.id) {
            lancamentosConferidos.remove(lancamento.id)
        } else {
            lancamentosConferidos.insert(lancamento.id)
        }
    }

    private func exportarCSV() async {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            let url = try await ExportarLancamentos.export(
                lancamentos: lancamentos,
                fileName: "lancamentos_fatura.csv"
            )
            shareItem = ShareItem(url: url)
        } catch {
            print("Erro ao exportar CSV:", error)
        }
    }
}

struct LancamentoConferenciaRow: View {
    let lancamento: LancamentoModel
    let selecionado: Bool

    var body: some View {
        HStack {
            LancamentoRow(
                lancamento: lancamento,
                mostrarPagamento: false,
                mostrarValores: true,
                mostrarData: true
            )

            Spacer()

            Image(systemName: selecionado ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(selecionado ? Color.accentColor : .secondary)
        }
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: selecionado)
    }
}

enum OrdemData: CaseIterable {
    case crescente
    case decrescente

    var titulo: String {
        self == .crescente ? "Crescente" : "Decrescente"
    }

    var icon: String {
        self == .crescente ? "arrow.up" : "arrow.down"
    }
}
