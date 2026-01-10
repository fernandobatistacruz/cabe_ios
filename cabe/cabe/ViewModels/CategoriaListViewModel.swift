//
//  CategoriaViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 10/01/26.
//

import SwiftUI
import GRDB
import Combine

@MainActor
final class CategoriaListViewModel: ObservableObject {
    
    @Published var categorias: [CategoriaModel] = []
    private let repository: CategoriaRepository
    private var dbCancellable: AnyDatabaseCancellable?
    private var cancellables: Set<AnyCancellable> = []
    
    
    init(repository: CategoriaRepository) {
        self.repository = repository
        observarCategorias()
    }
    
    deinit {
        dbCancellable?.cancel()
    }
  
    private func observarCategorias() {
        dbCancellable = repository.observeCategorias { [weak self] contas in
            self?.categorias = contas
        }
    }
   
    // --- Métodos existentes mantidos ---
    
    func salvar(_ categoria: inout CategoriaModel) {
        do { try repository.salvar(categoria) }
        catch { print("Erro ao salvar conta:", error) }
    }
    
    func editar(_ categoria: CategoriaModel) {
        do { try repository.editar(categoria) }
        catch { print("Erro ao editar conta:", error) }
    }
    
    func remover(_ categoria: CategoriaModel) {
        do {
            try repository
                .remover(id: categoria.id ?? 0, tipo: categoria.tipo)
        }
        catch { print("Erro ao remover conta:", error) }
    }
    
    func limparDados() {
        do { try repository.limparDados() }
        catch { print("Erro ao limpar dados:", error) }
    }
   
    func listar() -> [CategoriaModel] {
        do { return try repository.listar() }
        catch { print("Erro ao listar contas:", error); return [] }
    }
}


