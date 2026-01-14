import SwiftUI
import GRDB
import Combine

@MainActor
final class ContaListViewModel: ObservableObject {
    
    @Published var contas: [ContaModel] = []
    @Published private(set) var saldoTotal: Decimal = 0.0 // <- saldo em Decimal
    @Published var pagamentoPadrao: MeioPagamento? = UserDefaults.standard.carregarPagamentoPadrao()
    
    private let repository: ContaRepository
    private var dbCancellable: AnyDatabaseCancellable?
    private var cancellables: Set<AnyCancellable> = []
    
    
    init(repository: ContaRepository) {
        self.repository = repository
        observarContas()
        observarSaldoTotal()
    }
    
    deinit {
        dbCancellable?.cancel()
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
    
    func salvar(_ conta: ContaModel) async {
        do { try await repository.salvar(conta) }
        catch { print("Erro ao salvar conta:", error) }
    }
    
    func editar(_ conta: ContaModel) async {
        do { try await repository.editar(conta) }
        catch { print("Erro ao editar conta:", error) }
    }
    
    func remover(_ conta: ContaModel) async {
        do {
            try await repository.remover(id: conta.id ?? 0, uuid: conta.uuid)
            limparPagamentoPadraoSeNecessario(deletado: .conta(conta))
        }
        catch { print("Erro ao remover conta:", error) }
    }
   
    func listar() -> [ContaModel] {
        do { return try repository.listar() }
        catch { print("Erro ao listar contas:", error); return [] }
    }
    
    private func limparPagamentoPadraoSeNecessario(deletado: MeioPagamento) {
        if pagamentoPadrao == deletado {
            UserDefaults.standard.removeObject(forKey: AppSettings.pagamentoPadrao)
            pagamentoPadrao = nil
        }
    }
}


