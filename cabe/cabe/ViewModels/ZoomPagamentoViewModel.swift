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
            cartoes = try cartaoRepository.listar()
            contas = try contaRepository.listar()
        } catch {
            print("Erro ao carregar meios de pagamento: \(error)")
        }
    }
}
