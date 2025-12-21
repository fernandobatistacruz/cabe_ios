import SwiftUI
import GRDB
internal import Combine

@MainActor
final class ContaListViewModel: ObservableObject {
    
    @Published var contas: [ContaModel] = []
    
    private let repository: ContaRepository
    private var dbCancellable: AnyDatabaseCancellable?
    
    init(repository: ContaRepository) {
        self.repository = repository
        observarContas()
    }
  
    private func observarContas() {
        dbCancellable = repository.observeContas { [weak self] contas in
            self?.contas = contas
        }
    }
   
    func salvar(_ conta: inout ContaModel) {
        do { try repository.salvar(&conta) }
        catch { print("Erro ao salvar conta:", error) }
    }
    
    func editar(_ conta: ContaModel) {
        do { try repository.editar(conta) }
        catch { print("Erro ao editar conta:", error) }
    }
    
    func remover(id: Int64, uuid: String) {
        do { try repository.remover(id: id, uuid: uuid) }
        catch { print("Erro ao remover conta:", error) }
    }
    
    func limparDados() {
        do { try repository.limparDados() }
        catch { print("Erro ao limpar dados:", error) }
    }
   
    func listar() -> [ContaModel] {
        do { return try repository.listar() }
        catch { print("Erro ao listar contas:", error); return [] }
    }
    
    func consultarPorUuid(_ uuid: String) -> [ContaModel] {
        do { return try repository.consultarPorUuid(uuid) }
        catch { print("Erro ao consultar por UUID:", error); return [] }
    }
    
    deinit {
        dbCancellable?.cancel()
    }
}
