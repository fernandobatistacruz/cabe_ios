//
//  BuscaViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 25/01/26.
//

import Foundation
import Combine

@MainActor
final class BuscarViewModel: ObservableObject {

    @Published var texto = ""
    @Published var resultados: [LancamentoModel] = []
    @Published var carregando = false
    @Published var buscou = false

    private let repository = LancamentoRepository()
    private var task: Task<Void, Never>?

    func onTextoChange(_ novoTexto: String) {
        task?.cancel()

        guard novoTexto.count >= 2 else {
            resultados = []
            buscou = false
            carregando = false
            return
        }

        carregando = true
        buscou = false

        let textoAtual = novoTexto

        task = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return // 🔐 cancelada durante o debounce
            }

            guard !Task.isCancelled else { return }
            guard textoAtual == texto else { return }

            await buscar(textoAtual)
        }
    }

    private func buscar(_ textoBuscado: String) async {
        guard !Task.isCancelled else { return }

        do {
            let dados = try await repository.buscarLancamentos(texto: textoBuscado)

            guard !Task.isCancelled else { return }
            guard textoBuscado == texto else { return }

            resultados = dados
            buscou = true
        } catch {
            guard !Task.isCancelled else { return }
            resultados = []
            buscou = true
        }

        carregando = false
    }

    func recarregarSeNecessario() {
        guard texto.count >= 2 else { return }

        task?.cancel()
        carregando = true
        buscou = false

        let textoAtual = texto

        task = Task {
            guard !Task.isCancelled else { return }
            await buscar(textoAtual)
        }
    }
}
