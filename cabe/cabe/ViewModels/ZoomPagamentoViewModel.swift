//
//  ZoomPagamentoViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/12/25.
//

import Combine

@MainActor
final class ZoomPagamentoViewModel: ObservableObject {

    @Published var cartoes: [CartaoModel] = []
    @Published var contas: [ContaModel] = []

    private let cartaoRepository = CartaoRepository()
    private let contaRepository = ContaRepository()

    func carregarDados() {
        do {
            let todos = try cartaoRepository.listar()
            //TODO: Deve vir filtrado do banco
            cartoes = todos.filter { $0.arquivado == 0 }
            
            contas = try contaRepository.listar()
        } catch {
            print("Erro ao carregar meios de pagamento: \(error)")
        }
    }
}
