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

    deinit {
        task?.cancel()
    }

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

        task = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return
            }

            guard let self else { return }
            guard !Task.isCancelled else { return }

            await self.buscar(novoTexto)
        }
    }

    private func buscar(_ textoBuscado: String) async {
        guard !Task.isCancelled else { return }

        do {
            let dados = try await repository.buscarLancamentos(texto: textoBuscado)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.resultados = dados
                self.buscou = true
                self.carregando = false
            }

        } catch {
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.resultados = []
                self.buscou = true
                self.carregando = false
            }
        }
    }

    func recarregarSeNecessario(texto: String) {
        guard texto.count >= 2 else { return }

        task?.cancel()
        carregando = true
        buscou = false

        task = Task { [weak self] in
            guard let self else { return }
            guard !Task.isCancelled else { return }

            await self.buscar(texto)
        }
    }
}
