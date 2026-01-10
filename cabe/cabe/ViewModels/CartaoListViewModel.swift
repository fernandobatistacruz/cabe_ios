//
//  CartaoListViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import SwiftUI
import GRDB
import Combine

@MainActor
final class CartaoListViewModel: ObservableObject {
    
    @Published var cartoes: [CartaoModel] = []
    @Published var pagamentoPadrao: MeioPagamento? = UserDefaults.standard.carregarPagamentoPadrao()
    
    private let repository: CartaoRepository
    private var dbCancellable: AnyDatabaseCancellable?
    
    init(repository: CartaoRepository) {
        self.repository = repository
        observarCartoes()
    }
    
    deinit {
        dbCancellable?.cancel()
    }
  
    private func observarCartoes() {
        dbCancellable = repository.observeCartoes { [weak self] cartoes in
            self?.cartoes = cartoes
        }
    }
   
    func salvar(_ cartao: inout CartaoModel) {
        do { try repository.salvar(&cartao) }
        catch { print("Erro ao salvar cartão:", error) }
    }
    
    func editar(_ cartao: CartaoModel) {
        do { try repository.editar(cartao) }
        catch { print("Erro ao editar cartão:", error) }
    }
    
    func remover(_ cartao: CartaoModel) {
        do {
            try repository.remover(id: cartao.id ?? 0, uuid: cartao.uuid)
            limparPagamentoPadraoSeNecessario(deletado: .cartao(cartao))
        }
        catch { print("Erro ao remover cartão:", error) }
    }
    
    func limparDados() {
        do { try repository.limparDados() }
        catch { print("Erro ao limpar dados:", error) }
    }
   
    func listar() -> [CartaoModel] {
        do { return try repository.listar() }
        catch { print("Erro ao listar cartões:", error); return [] }
    }
    
    func consultarPorUuid(_ uuid: String) -> [CartaoModel] {
        do { return try repository.consultarPorUuid(uuid) }
        catch { print("Erro ao consultar por UUID:", error); return [] }
    }
    
    private func limparPagamentoPadraoSeNecessario(deletado: MeioPagamento) {
        if pagamentoPadrao == deletado {
            UserDefaults.standard.removeObject(forKey: AppSettings.pagamentoPadrao)
            pagamentoPadrao = nil
        }
    }
}
