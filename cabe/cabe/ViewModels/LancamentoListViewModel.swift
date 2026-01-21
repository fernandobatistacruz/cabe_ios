//
//  LancamentoListViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import SwiftUI
import GRDB
import Combine

@MainActor
final class LancamentoListViewModel: ObservableObject {
    
    @Published var lancamentos: [LancamentoModel] = []
    private var dbCancellableLancamentos: AnyDatabaseCancellable?
    
    @Published var lancamentosRecentes: [LancamentoModel] = []
    private var dbCancellableRecentes: AnyDatabaseCancellable?
    
    @Published var notificacaoVM = NotificacaoViewModel()
    
    var notificacoesAtivas: Bool = UserDefaults.standard.bool(forKey: AppSettings.notificacoesAtivas)
    
    @Published private(set) var lancamentosNotificacao: [LancamentoModel] = []
    private var dbCancellableNotificacao: AnyDatabaseCancellable?
    
    @Published private(set) var mesAtual: Int
    @Published private(set) var anoAtual: Int
    
    let repository: LancamentoRepository
    
    init(
        repository: LancamentoRepository,
        mes: Int? = nil,
        ano: Int? = nil
    ) {
        self.repository = repository

        let hoje = Date()
        self.mesAtual = mes ?? Calendar.current.component(.month, from: hoje)
        self.anoAtual = ano ?? Calendar.current.component(.year, from: hoje)

        observarLancamentos()
        observarLancamentosRecentes()
        observarLancamentosNotificacao()
    }
    
    deinit {
        dbCancellableLancamentos?.cancel()
        dbCancellableRecentes?.cancel()
        dbCancellableNotificacao?.cancel()
    }
    
    var totalNotificacoes: Int {
        notificacaoVM.vencidos.count +
        notificacaoVM.vencemHoje.count +
        notificacaoVM.cartoesVencidos.count +
        notificacaoVM.cartoesVenceHoje.count
    }
    
    private func observarLancamentos() {
        dbCancellableLancamentos?.cancel()

        dbCancellableLancamentos = repository.observeLancamentos(
            mes: mesAtual,
            ano: anoAtual
        ) { [weak self] lancamentos in
            guard let self = self else { return }

            self.lancamentos = lancamentos
        }
    }

    
    private func observarLancamentosRecentes() {
        dbCancellableRecentes?.cancel()
        
        dbCancellableRecentes = repository.observeLancamentosRecentes { [weak self] lancamentos in
            self?.lancamentosRecentes = lancamentos
        }
    }
    
    private func observarLancamentosNotificacao() {
        dbCancellableNotificacao?.cancel()

        dbCancellableNotificacao = repository.observeLancamentosParaNotificacao {
            [weak self] lancamentos in
            guard let self else { return }

            self.lancamentosNotificacao = lancamentos
            self.notificacaoVM.atualizar(lancamentos: lancamentos)
        }
    }
    
    var gastosPorCategoriaResumo: [CategoriaResumo] {

        let despesas = lancamentos.filter {
            $0.tipo == Tipo.despesa.rawValue &&
            !$0.transferencia
        }

        let agrupado = Dictionary(grouping: despesas, by: \.categoriaID)

        var totais: [(categoriaID: Int64, nome: String, valor: Double, cor: Color)] =
        agrupado.compactMap { (categoriaID, lancamentos) in
            guard let primeiro = lancamentos.first else { return nil }
            
            let total = lancamentos.reduce(0.0) {
                $0 + ($1.valor as NSDecimalNumber).doubleValue
            }
            
            return (
                categoriaID: categoriaID,
                nome: primeiro.categoria?.nome ?? "Sem categoria",
                valor: total,
                cor: primeiro.categoria?.getCor().cor ?? .gray
            )
        }

        totais.sort { $0.valor > $1.valor }

        let totalGeral = totais.reduce(0) { $0 + $1.valor }
        guard totalGeral > 0 else { return [] }

        // Top 2
        let top2 = totais.prefix(2).map {
            CategoriaResumo(
                categoriaID: $0.categoriaID,
                nome: $0.nome,
                valor: $0.valor,
                percentual: ($0.valor / totalGeral) * 100,
                cor: $0.cor
            )
        }

        // Outros
        if totais.count > 2 {
            let outrosValor = totais.dropFirst(2).reduce(0) { $0 + $1.valor }

            let outros = CategoriaResumo(
                categoriaID: -1, // ⚠️ marcador especial
                nome: "Outros",
                valor: outrosValor,
                percentual: (outrosValor / totalGeral) * 100,
                cor: .secondary
            )

            return top2 + [outros]
        }

        return top2

    }
    
    var gastosPorCategoriaDetalhado: [CategoriaResumo] {

        let despesas = lancamentos.filter {
            $0.tipo == Tipo.despesa.rawValue &&
            !$0.transferencia
        }

        let agrupado = Dictionary(grouping: despesas, by: \.categoriaID)

        let totaisBase = agrupado.compactMap { (categoriaID, lancamentos)
            -> (categoriaID: Int64, nome: String, valor: Double, cor: Color)? in

            guard let primeiro = lancamentos.first else { return nil }

            let valor = lancamentos.reduce(0.0) {
                $0 + ($1.valor as NSDecimalNumber).doubleValue
            }

            return (
                categoriaID: categoriaID,
                nome: primeiro.categoria?.nome ?? "Sem categoria",
                valor: valor,
                cor: primeiro.categoria?.getCor().cor ?? .gray
            )
        }


        let totalGeral = totaisBase.reduce(0) { $0 + $1.valor }
        guard totalGeral > 0 else { return [] }

        return totaisBase
            .sorted { $0.valor > $1.valor }
            .map {
                CategoriaResumo(
                    categoriaID: $0.categoriaID,
                    nome: $0.nome,
                    valor: $0.valor,
                    percentual: ($0.valor / totalGeral) * 100,
                    cor: $0.cor
                )
            }

    }
    
    func selecionar(data: Date) {
        let calendar = Calendar.current
        mesAtual = calendar.component(.month, from: data)
        anoAtual = calendar.component(.year, from: data)
        observarLancamentos()
    }
   
    func salvar(_ lancamento: LancamentoModel) async {
        do { try await repository.salvar(lancamento) }
        catch { print("Erro ao salvar lançamento:", error) }
    }
    
    func editar(_ lancamento: LancamentoModel) async {
        do { try await repository.editar(lancamento) }
        catch { print("Erro ao editar lançamento:", error) }
    }
    
    func remover(id: Int64, uuid: String) async{
        do { try await repository.remover(id: id, uuid: uuid) }
        catch { print("Erro ao remover lançamento:", error) }
    }
    
    func removerSomenteEste(_ lancamento: LancamentoModel) async {
        guard let id = lancamento.id else { return }
        await remover(id: id, uuid: lancamento.uuid)
    }

    func removerTodosRecorrentes(_ lancamento: LancamentoModel) async {
        do { try await repository.removerRecorrentes(uuid: lancamento.uuid) }
        catch { print("Erro ao remover lançamento:", error) }
    }
    
    func removerEsteEProximos(_ lancamento: LancamentoModel) async {
        do {
            try await repository
                .removerEsteEProximos(uuid: lancamento.uuid, mes: lancamento.mes, ano: lancamento.ano)
        }
        catch { print("Erro ao remover lançamento:", error) }
    }
    
    func togglePago(_ lancamentos: [LancamentoModel]) async {
        do { try await repository.togglePago(lancamentos) }
        catch { print("Erro ao alternar pagamento:", error) }
    }
    
    var totalCartao: Decimal {
        lancamentosCartao.reduce(0) { $0 + $1.valor }
    }
    
    var totalDespesasCartao: Decimal {
        lancamentosCartao
            .filter { $0.tipo == Tipo.despesa.rawValue }
            .reduce(0) { $0 + $1.valor }
    }
    
    var totalDespesas: Decimal {
        despesas.reduce(0) { $0 + $1.valor }
    }
    
    var totalReceitas: Decimal {
        receitas.reduce(0) { $0 + $1.valor }
    }
    
    var balanco: Decimal {
        lancamentos.reduce(0) { $0 + $1.valorComSinal }
    }

}

extension LancamentoListViewModel {
    // MARK: - Filtros base

    private var lancamentosCartao: [LancamentoModel] {
        lancamentos.filter { !$0.cartaoUuid.isEmpty }
    }

    private var despesas: [LancamentoModel] {
        lancamentos.filter { $0.tipo == Tipo.despesa.rawValue }
    }

    private var receitas: [LancamentoModel] {
        lancamentos.filter { $0.tipo == Tipo.receita.rawValue }
    }
}

struct CategoriaResumo: Identifiable {
    let id = UUID()
    let categoriaID: Int64
    let nome: String
    let valor: Double
    let percentual: Double
    let cor: Color

    var valorFormatado: String {
        valor.formatted(
            .currency(code: Locale.current.currency?.identifier ?? "USD")
        )
    }
}

extension LancamentoListViewModel {
  
    var lancamentosRecentesAgrupadosSimples: [(date: Date, items: [LancamentoModel])] {

        // Evita duplicidade de UUID, pega os 10 mais recentes
        var vistos: Set<String> = []
        
        lancamentosRecentes.forEach {
            print($0.dataCriacaoDate)
        }


        let recentes = lancamentosRecentes
            .sorted { $0.dataCriacaoDate > $1.dataCriacaoDate }
            .filter { lancamento in
                guard !vistos.contains(lancamento.uuid) else { return false }
                vistos.insert(lancamento.uuid)
                return true
            }
            .prefix(10)
        
        recentes.forEach {
            print($0.dataCriacaoDate)
        }

        // Agrupa por dia
        let porData = Dictionary(grouping: recentes) { lancamento in
            Calendar.current.startOfDay(for: lancamento.dataCriacaoDate)
        }

        // Retorna já como [LancamentoModel]
        return porData.map { (date, lancamentosDoDia) in
            (date: date, items: lancamentosDoDia)
        }
        .sorted { $0.date > $1.date }
    }
}

enum AppStorageWrapper {
    static var notificacoesAtivas: Bool {
        UserDefaults.standard.bool(
            forKey: AppSettings.notificacoesAtivas
        )
    }
}

