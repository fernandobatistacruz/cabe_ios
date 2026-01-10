import SwiftUI
import GRDB
import Combine

@MainActor
final class ContaListViewModel: ObservableObject {
    
    @Published var contas: [ContaModel] = []
    @Published private(set) var saldoTotal: Decimal = 0.0 // <- saldo em Decimal
    
    private let repository: ContaRepository
    private var dbCancellable: AnyDatabaseCancellable?
    private var cancellables: Set<AnyCancellable> = []
    
    init(repository: ContaRepository) {
        self.repository = repository
        observarContas()
        observarSaldoTotal()
    }
  
    private func observarContas() {
        dbCancellable = repository.observeContas { [weak self] contas in
            self?.contas = contas
        }
    }
    
    private func observarSaldoTotal() {
        // Converte cada saldo Double em Decimal e soma
        $contas
            .map { contas in
                contas.reduce(Decimal(0)) { $0 + Decimal($1.saldo) }
            }
            .assign(to: \.saldoTotal, on: self)
            .store(in: &cancellables)
    }
   
    // --- Métodos existentes mantidos ---
    
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


