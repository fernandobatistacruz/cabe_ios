import SwiftUI

struct CartaoFaturaView: View {
    let viewModel: LancamentoListViewModel
    let cartao: CartaoModel
    let lancamentos: [LancamentoModel]
    let total: Decimal
    let vencimento: Date

    @State private var searchText = ""
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var shareItem: ShareItem?
    @State private var lancamentoParaExcluir: LancamentoModel?
    @State private var mostrarDialogExclusao = false
    @State private var ordemData: OrdemData = .decrescente
    @State private var filtroSelecionado: FiltroLancamento = .todos

    // 🔹 Estados da conferência
    @State private var modoConferencia = false
    @State private var lancamentosConferidos: Set<LancamentoModel.ID> = []

    var filtroLancamentos: [LancamentoModel] {
        var resultado = searchText.isEmpty
            ? lancamentos
            : lancamentos.filter {
                $0.descricao.localizedCaseInsensitiveContains(searchText)
            }

        // 🔹 Filtro por tipo
        switch filtroSelecionado {
        case .todos:
            break

        case .recorrentes:
            resultado = resultado.filter {
                $0.tipoRecorrente != .nunca
            }

        case .parcelados:
            resultado = resultado.filter {
                $0.tipoRecorrente == .parcelado
            }

        case .divididos:
            resultado = resultado.filter {
                $0.dividido
            }
        }

        // 🔹 Ordenação por data
        resultado.sort(by: {
            ordemData == .crescente
            ? $0.dataCompraFormatada < $1.dataCompraFormatada
            : $0.dataCompraFormatada > $1.dataCompraFormatada
        })

        return resultado
    }
    
    private var filtroAtivo: Bool {
        ordemData != .decrescente || filtroSelecionado != .todos
    }
    
    // 🔹 Total dinâmico da conferência
    var totalConferido: Decimal {
        lancamentos
            .filter { lancamentosConferidos.contains($0.id) }
            .map(\.valor)
            .reduce(0, +)
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
                        .font(.title3.bold())
                        .lineLimit(2)
                        .truncationMode(.tail)

                    Text(vencimento.formatted(date: .numeric, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading) // 🔑 ocupa o espaço flexível

                Text(
                    modoConferencia ? totalConferido : total,
                    format: .currency(
                        code: lancamentos.first?.currencyCode ?? "USD"
                    )
                )
                .font(.title2.bold())
                .foregroundStyle(
                    modoConferencia ? Color.accentColor : .secondary
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
                                    repository: viewModel.repository
                                )
                            } label: {
                                LancamentoRow(
                                    lancamento: lancamento,
                                    mostrarPagamento: false,
                                    mostrarValores: true
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
        .navigationTitle("Fatura")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)

        // 🔹 Busca (mantida)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Buscar", text: $searchText)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .clipShape(Capsule())
            }
        }

        // 🔹 Toolbar superior
        .toolbar {
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
                        ForEach(FiltroLancamento.allCases) { filtro in
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
                          : "line.3.horizontal.decrease")
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

            // 🔹 Botão OK no modo conferência
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

        // 🔹 Estado vazio
        .overlay {
            if filtroLancamentos.isEmpty {
                Text("Nenhum lançamento")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }

        // 🔹 Share
        .sheet(item: $shareItem) { item in
            ShareSheetView(activityItems: [item.url])
        }

        // 🔹 Overlay exportação
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    ProgressView().scaleEffect(1.2)
                }
            }
        }

        // 🔹 Confirmação exclusão
        .confirmationDialog(
            "Excluir Lançamento?",
            isPresented: $mostrarDialogExclusao
        ) {
            let repository = LancamentoRepository()
            
            if let lancamento = lancamentoParaExcluir {
                if lancamento.tipoRecorrente == .nunca {
                    Button("Confirmar Exclusão", role: .destructive) {
                        Task {
                            try await repository.removerRecorrentes(uuid: lancamento.uuid)
                        }
                    }
                } else {
                    Button("Excluir Somente Este", role: .destructive) {
                        Task {
                            try await repository.remover(
                                    id: lancamento.id ?? 0,
                                    uuid: lancamento.uuid
                                )
                        }
                    }
                    Button("Excluir Este e os Próximos", role: .destructive) {
                        Task { try await repository.removerEsteEProximos(
                            uuid: lancamento.uuid,
                            mes: lancamento.mes,
                            ano: lancamento.ano
                            )
                        }
                    }
                    Button("Excluir Todos", role: .destructive) {
                        Task { try await repository.removerRecorrentes(uuid: lancamento.uuid)  }
                    }
                }
            }
        } message: {
            Text("Essa ação não poderá ser desfeita.")
        }
 
    }

    // 🔹 Toggle seleção
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
                mostrarValores: true
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

enum FiltroLancamento: String, CaseIterable, Identifiable {
    case todos
    case parcelados
    case divididos
    case recorrentes

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .todos: return "Todos"
        case .parcelados: return "Parcelados"
        case .divididos: return "Divididos"
        case .recorrentes: return "Recorrentes"
        }
    }

    var icon: String {
        switch self {
        case .todos: return "tray.full"
        case .parcelados: return "calendar"
        case .divididos: return "person.2"
        case .recorrentes: return "repeat"
        }
    }
}
