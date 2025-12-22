//
//  CartaoListViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import SwiftUI
import GRDB
internal import Combine

@MainActor
final class CartaoListViewModel: ObservableObject {
    
    @Published var cartoes: [CartaoModel] = []
    
    private let repository: CartaoRepository
    private var dbCancellable: AnyDatabaseCancellable?
    
    init(repository: CartaoRepository) {
        self.repository = repository
        observarCartoes()
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
    
    func remover(id: Int64, uuid: String) {
        do { try repository.remover(id: id, uuid: uuid) }
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
    
    deinit {
        dbCancellable?.cancel()
    }
}
