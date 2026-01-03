//
//  LancamentoListViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import SwiftUI
import GRDB
internal import Combine

@MainActor
final class LancamentoListViewModel: ObservableObject {
    
    @Published var lancamentos: [LancamentoModel] = []
    @Published private(set) var mesAtual: Int
    @Published private(set) var anoAtual: Int

    
    private let repository: LancamentoRepository
    private var dbCancellable: AnyDatabaseCancellable?
    
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
    }


    private func observarLancamentos() {
        dbCancellable?.cancel()

        dbCancellable = repository.observeLancamentos(
            mes: mesAtual,
            ano: anoAtual
        ) { [weak self] lancamentos in
            self?.lancamentos = lancamentos
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
    
    func limparDados() async {
        do { try await repository.limparDados() }
        catch { print("Erro ao limpar dados:", error) }
    }
    
    func consultarPorUuid (_ uuid: String) async -> [LancamentoModel] {
        do { return try await repository.consultarPorUuid(uuid) }
        catch { print("Erro ao consultar por UUID:", error); return [] }
    }
    
    func togglePago(_ lancamentos: [LancamentoModel]) async {
        do { try await repository.togglePago(lancamentos) }
        catch { print("Erro ao alternar pagamento:", error) }
    }
    
    deinit {
        dbCancellable?.cancel()
    }
}
