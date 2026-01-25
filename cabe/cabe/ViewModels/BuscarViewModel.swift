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

        let textoAtual = novoTexto  // 🔐 captura segura

        task = Task {
            try? await Task.sleep(for: .milliseconds(300))

            // Se o texto mudou, ignora
            guard textoAtual == self.texto else { return }

            await buscar(textoAtual)
        }
    }

    private func buscar(_ textoBuscado: String) async {
        do {
            let dados = try await repository.buscarLancamentos(texto: textoBuscado)

            // Se o texto mudou durante a busca, ignora
            guard textoBuscado == texto else { return }

            resultados = dados
        } catch {
            resultados = []
        }

        carregando = false
        buscou = true
    }
    
    func recarregarSeNecessario() {
        guard texto.count >= 2 else { return }

        task?.cancel()
        carregando = true
        buscou = false

        let textoAtual = texto

        task = Task {
            await buscar(textoAtual)
        }
    }
}
