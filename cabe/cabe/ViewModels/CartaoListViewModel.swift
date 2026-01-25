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
   
    func salvar(_ cartao: inout CartaoModel) async {
        do { try await repository.salvar(cartao) }
        catch { print("Erro ao salvar cartão:", error) }
    }
    
    func editar(_ cartao: CartaoModel) async {
        do { try await repository.editar(cartao) }
        catch { print("Erro ao editar cartão:", error) }
    }
    
    func remover(_ cartao: CartaoModel) async {
        do {
            try await repository.remover(id: cartao.id ?? 0, uuid: cartao.uuid)
            limparPagamentoPadraoSeNecessario(deletado: .cartao(cartao))
        }
        catch { print("Erro ao remover cartão:", error) }
    }
   
    func listar() -> [CartaoModel] {
        do { return try repository.listar() }
        catch { print("Erro ao listar cartões:", error); return [] }
    }
    
    func toggleArquivado(_ cartoes: [CartaoModel]) async {
        do { try await repository.toggleArquivado(cartoes) }
        catch { print("Erro ao alternar pagamento:", error) }
    }
    
    private func limparPagamentoPadraoSeNecessario(deletado: MeioPagamento) {
        if pagamentoPadrao == deletado {
            UserDefaults.standard.removeObject(forKey: AppSettings.pagamentoPadrao)
            pagamentoPadrao = nil
        }
    }
}
