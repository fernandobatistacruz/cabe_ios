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

        // 🔑 normaliza subcategoria → pai
        let normalizados = despesas.map { lancamento -> (id: Int64, nome: String, cor: Color, valor: Double) in
            let info = categoriaPrincipalInfo(from: lancamento.categoria)
            let valor = (lancamento.valor as NSDecimalNumber).doubleValue

            return (
                id: info.id,
                nome: info.nome,
                cor: info.cor,
                valor: valor
            )
        }

        // 🔑 agrupa já com categoria final
        let agrupado = Dictionary(grouping: normalizados, by: \.id)

        let totais = agrupado.map { (_, itens) in
            (
                id: itens.first!.id,
                nome: itens.first!.nome,
                cor: itens.first!.cor,
                valor: itens.reduce(0) { $0 + $1.valor }
            )
        }
        .sorted { $0.valor > $1.valor }

        let totalGeral = totais.reduce(0) { $0 + $1.valor }
        guard totalGeral > 0 else { return [] }

        // ✅ regra: até 3 categorias, senão a 3ª vira "Outros"
        var resultado: [CategoriaResumo] = []

        if totais.count <= 3 {
            resultado = totais.map {
                CategoriaResumo(
                    categoriaID: $0.id,
                    nome: $0.nome,
                    valor: $0.valor,
                    percentual: ($0.valor / totalGeral) * 100,
                    cor: $0.cor,
                    currencyCode: lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode
                )
            }
        } else {
            let principais = Array(totais.prefix(2))
            let outros = Array(totais.dropFirst(2))

            let valorOutros = outros.reduce(0) { $0 + $1.valor }

            resultado = principais.map {
                CategoriaResumo(
                    categoriaID: $0.id,
                    nome: $0.nome,
                    valor: $0.valor,
                    percentual: ($0.valor / totalGeral) * 100,
                    cor: $0.cor,
                    currencyCode: lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode
                )
            }

            resultado.append(
                CategoriaResumo(
                    categoriaID: -1,
                    nome: "Outros",
                    valor: valorOutros,
                    percentual: (valorOutros / totalGeral) * 100,
                    cor: .gray,
                    currencyCode: lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode
                )
            )
        }

        return resultado
    }
    
    var gastosPorCategoriaDetalhado: [CategoriaResumo] {

        let despesas = lancamentos.filter {
            $0.tipo == Tipo.despesa.rawValue &&
            !$0.transferencia
        }

        // 🔑 NORMALIZA antes de agrupar
        let normalizados = despesas.map { lancamento -> (id: Int64, nome: String, cor: Color, valor: Double) in
            let info = categoriaPrincipalInfo(from: lancamento.categoria)
            let valor = (lancamento.valor as NSDecimalNumber).doubleValue

            return (
                id: info.id,
                nome: info.nome,
                cor: info.cor,
                valor: valor
            )
        }

        // 🔑 agora sim agrupa corretamente
        let agrupado = Dictionary(grouping: normalizados, by: \.id)

        let totaisBase = agrupado.map { (_, itens) in
            (
                categoriaID: itens.first!.id,
                nome: itens.first!.nome,
                valor: itens.reduce(0) { $0 + $1.valor },
                cor: itens.first!.cor
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
                    cor: $0.cor,
                    currencyCode: lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode
                )
            }
    }
    
    private func categoriaPrincipalInfo(
        from categoria: CategoriaModel?
    ) -> (id: Int64, nome: String, cor: Color) {
        if let categoria, categoria.isSub, let paiID = categoria.pai {
            return (
                id: paiID,
                nome: categoria.nome,
                cor: categoria.getCor().cor
            )
        }

        return (
            id: categoria?.id ?? 0,
            nome: categoria?.nome ?? "",
            cor: categoria?.getCor().cor ?? .gray
        )
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
        despesas.reduce(0) { total, lancamento in
            let valorConsiderado = lancamento.dividido
                ? lancamento.valor / 2
                : lancamento.valor

            return total + valorConsiderado
        }
    }
    
    var totalReceitas: Decimal {
        receitas.reduce(0) { $0 + $1.valor }
    }
    
    var balanco: Decimal {
        totalReceitas - totalDespesas
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
    let currencyCode: String

    var valorFormatado: String {
        valor.formatted(
            .currency(code: currencyCode)
        )
    }
}

extension LancamentoListViewModel {
  
    var lancamentosRecentesAgrupadosSimples: [(date: Date, items: [LancamentoModel])] {

        // Evita duplicidade de UUID, pega os 10 mais recentes
        var vistos: Set<String> = []

        let recentes = lancamentosRecentes
            .sorted { $0.dataCriacaoDate > $1.dataCriacaoDate }
            .filter { lancamento in
                guard !vistos.contains(lancamento.uuid) else { return false }
                vistos.insert(lancamento.uuid)
                return true
            }
            .prefix(10)

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
