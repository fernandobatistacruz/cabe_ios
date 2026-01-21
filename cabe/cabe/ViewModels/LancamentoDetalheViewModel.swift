//
//  LancamentoDetalheViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 20/01/26.
//

import Foundation
import Combine
import GRDB

@MainActor
final class LancamentoDetalheViewModel: ObservableObject {

    @Published var lancamento: LancamentoModel?

    private var cancellable: AnyDatabaseCancellable?

    init(
        id: Int64,
        uuid: String,
        repository: LancamentoRepository
    ) {
        cancellable = repository.observeLancamento(
            id: id,
            uuid: uuid
        ) { [weak self] lancamento in
            self?.lancamento = lancamento
        }
    }
    
    deinit {
        cancellable?.cancel()
    }
}
