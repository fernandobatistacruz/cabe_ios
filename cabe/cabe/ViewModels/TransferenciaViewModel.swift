//
//  TransferenciaViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/01/26.
//

import Foundation
import GRDB
import Combine

// MARK: - ViewModel

@MainActor
final class TransferenciaViewModel: ObservableObject {

    @Published var contas: [ContaModel] = []
    @Published var valor: Decimal = 0
    @Published var descricao: String = "Transferência"
    @Published var contaOrigemUuid: String?
    @Published var contaDestinoUuid: String?

    private let useCase: TransferenciaUseCase

    /// ✅ Dependência injetada (SEM default argument)
    init(useCase: TransferenciaUseCase) {
        self.useCase = useCase
        loadContas()
    }

    // MARK: - Public API

    func loadContas() {
        do {
            contas = try useCase.carregarContas()
        } catch {
            print("Erro ao carregar contas:", error)
        }
    }

    func transferir() throws {
        guard
            let origem = contaOrigemUuid,
            let destino = contaDestinoUuid
        else {
            throw TransferenciaError.dadosInvalidos
        }

        try useCase.transferir(
            origemUuid: origem,
            destinoUuid: destino,
            valor: valor,
            descricao: descricao
        )

        loadContas()
    }
}

// MARK: - Errors

enum TransferenciaError: Error {
    case dadosInvalidos
}

final class TransferenciaUseCase {

    private let contaRepo: ContaRepositoryProtocol
    private let lancamentoRepo: LancamentoRepositoryProtocol
    private let db: AppDatabase

    /// ✅ Pode ter default arguments aqui (NÃO é MainActor)
    init(
        contaRepo: ContaRepositoryProtocol = ContaRepository(),
        lancamentoRepo: LancamentoRepositoryProtocol = LancamentoRepository(),
        db: AppDatabase = .shared
    ) {
        self.contaRepo = contaRepo
        self.lancamentoRepo = lancamentoRepo
        self.db = db
    }

    // MARK: - Queries

    func carregarContas() throws -> [ContaModel] {
        try contaRepo.listar()
    }

    // MARK: - Commands

    func transferir(
        origemUuid: String,
        destinoUuid: String,
        valor: Decimal,
        descricao: String
    ) throws {

        guard origemUuid != destinoUuid, valor > 0 else {
            throw TransferenciaError.dadosInvalidos
        }

        try db.dbQueue.write { db in

            // 🔹 Buscar contas dentro da transação
            guard
                var origem = try ContaModel
                    .filter(ContaModel.Columns.uuid == origemUuid)
                    .fetchOne(db),
                var destino = try ContaModel
                    .filter(ContaModel.Columns.uuid == destinoUuid)
                    .fetchOne(db)
            else {
                throw TransferenciaError.dadosInvalidos
            }

            // 🔹 Atualizar saldos
            origem.saldo -= (valor as NSDecimalNumber).doubleValue
            destino.saldo += (valor as NSDecimalNumber).doubleValue

            try origem.update(db)
            try destino.update(db)

            let hoje = Date()
            let cal = Calendar.current

            let dia = cal.component(.day, from: hoje)
            let mes = cal.component(.month, from: hoje)
            let ano = cal.component(.year, from: hoje)
            let dataISO = ISO8601DateFormatter().string(from: hoje)

            // 🔹 Lançamento saída
            let saida = LancamentoModel(
                id: nil,
                uuid: UUID().uuidString,
                descricao: descricao,
                anotacao: "",
                tipo: Tipo.despesa.rawValue,
                transferenciaRaw: 1,
                dia: dia,
                mes: mes,
                ano: ano,
                diaCompra: dia,
                mesCompra: mes,
                anoCompra: ano,
                categoriaID: 0,
                cartaoUuid: "",
                recorrente: 0,
                parcelas: 0,
                parcelaMes: "",
                valor: valor,
                pagoRaw: 1,
                divididoRaw: 0,
                contaUuid: origem.uuid,
                dataCriacao: dataISO,
                notificacaoLidaRaw: 1
            )

            // 🔹 Lançamento entrada
            let entrada = LancamentoModel(
                id: nil,
                uuid: UUID().uuidString,
                descricao: descricao,
                anotacao: "",
                tipo: Tipo.receita.rawValue,
                transferenciaRaw: 1,
                dia: dia,
                mes: mes,
                ano: ano,
                diaCompra: dia,
                mesCompra: mes,
                anoCompra: ano,
                categoriaID: 0,
                cartaoUuid: "",
                recorrente: 0,
                parcelas: 0,
                parcelaMes: "",
                valor: valor,
                pagoRaw: 1,
                divididoRaw: 0,
                contaUuid: destino.uuid,
                dataCriacao: dataISO,
                notificacaoLidaRaw: 1
            )

            try saida.insert(db)
            try entrada.insert(db)
        }
    }
}
