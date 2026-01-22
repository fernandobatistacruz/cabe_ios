//
//  LancamentoRepository.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import GRDB
import Foundation

final class LancamentoRepository : LancamentoRepositoryProtocol{
        
    fileprivate let db: AppDatabase
    
    init (db: AppDatabase = .shared){
        self.db = db
    }
    
    func observeLancamentos(
        mes: Int? = nil,
        ano: Int? = nil,
        onChange: @escaping ([LancamentoModel]) -> Void
    ) -> AnyDatabaseCancellable {

        let observation = ValueObservation.tracking { db in
            try self.listar(db: db, mes: mes, ano: ano)
        }

        return observation.start(
            in: db.dbQueue,
            onError: { print("Erro DB:", $0) },
            onChange: onChange
        )
    }
    
    func observeLancamentosRecentes(
        onChange: @escaping ([LancamentoModel]) -> Void
    ) -> AnyDatabaseCancellable {
        
        let observation = ValueObservation.tracking { db in
            try self.listarLancamentosRecentes(db: db)
        }
        
        return observation.start(
            in: db.dbQueue,
            onError: { print("Erro DB:", $0) },
            onChange: onChange
        )
    }
    
    func observeLancamentosParaNotificacao(
        onChange: @escaping ([LancamentoModel]) -> Void
    ) -> AnyDatabaseCancellable {

        let observation = ValueObservation.tracking { db in
            try self.listarLancamentosVencidosVenceHoje(db: db)
        }

        return observation.start(
            in: db.dbQueue,
            onError: { print("Erro DB (notificação):", $0) },
            onChange: onChange
        )
    }
    
    func observeLancamento(
        id: Int64,
        uuid: String,
        onChange: @escaping (LancamentoModel?) -> Void
    ) -> AnyDatabaseCancellable {

        let observation = ValueObservation.tracking { db in
            try self.listarLancamentoPorIdUUID(
                db: db,
                id: id,
                uuid: uuid
            )
        }

        return observation.start(
            in: db.dbQueue,
            onError: { print("Erro DB (detalhe):", $0) },
            onChange: onChange
        )
    }
    
    private nonisolated func listarLancamentoPorIdUUID(
        db: Database,
        id: Int64,
        uuid: String
    ) throws -> LancamentoModel? {

        let sql = """
            SELECT
                l.*,
                c.id AS "c.id", c.uuid AS "c.uuid", c.nome AS "c.nome", c.saldo AS "c.saldo", c.currency_code AS "c.currency_code",
                ca.id AS "ca.id", ca.uuid AS "ca.uuid", ca.nome AS "ca.nome", ca.vencimento AS "ca.vencimento",
                ca.fechamento AS "ca.fechamento", ca.operadora AS "ca.operadora", ca.arquivado AS "ca.arquivado",
                ca.conta_uuid AS "ca.conta_uuid", ca.limite AS "ca.limite",
                cat.id AS "cat.id", cat.nome AS "cat.nome", cat.nomeKey AS "cat.nomeKey", cat.nomeSubcategoria AS "cat.nomeSubcategoria",
                cat.tipo AS "cat.tipo", cat.icone AS "cat.icone", cat.cor AS "cat.cor", cat.pai AS "cat.pai"
            FROM lancamento l
            LEFT JOIN conta c ON l.conta_uuid = c.uuid
            LEFT JOIN cartao ca ON l.cartao_uuid = ca.uuid
            LEFT JOIN categoria cat ON l.categoria = cat.id AND l.tipo = cat.tipo
            WHERE l.id = ? AND l.uuid = ?
            LIMIT 1
        """

        guard let row = try Row.fetchOne(
            db,
            sql: sql,
            arguments: [id, uuid]
        ) else {
            return nil
        }

        return mapRows([row]).first
    }
    
    func listarLancamentosVencidosVenceHoje() async throws -> [LancamentoModel] {
        try await db.dbQueue.read { db in
            try self.listarLancamentosVencidosVenceHoje(db: db)
        }
    }
    
    private nonisolated func listarLancamentosVencidosVenceHoje(
        db: Database
    ) throws -> [LancamentoModel] {

        let sql = """
            SELECT
                l.*,
                c.id AS "c.id", c.uuid AS "c.uuid", c.nome AS "c.nome", c.saldo AS "c.saldo", c.currency_code AS "c.currency_code",
                ca.id AS "ca.id", ca.uuid AS "ca.uuid", ca.nome AS "ca.nome", ca.vencimento AS "ca.vencimento",
                ca.fechamento AS "ca.fechamento", ca.operadora AS "ca.operadora", ca.arquivado AS "ca.arquivado",
                ca.conta_uuid AS "ca.conta_uuid", ca.limite AS "ca.limite",
                cat.id AS "cat.id", cat.nome AS "cat.nome", cat.nomeKey AS "cat.nomeKey", cat.nomeSubcategoria AS "cat.nomeSubcategoria",
                cat.tipo AS "cat.tipo", cat.icone AS "cat.icone", cat.cor AS "cat.cor", cat.pai AS "cat.pai"
            FROM lancamento l
            LEFT JOIN conta c ON l.conta_uuid = c.uuid
            LEFT JOIN cartao ca ON l.cartao_uuid = ca.uuid
            LEFT JOIN categoria cat ON l.categoria = cat.id AND l.tipo = cat.tipo
            WHERE
                l.notificado = 0
            AND l.pago = 0
            AND
                DATE(
                    printf('%04d-%02d-%02d', l.ano, l.mes, l.dia)
                ) <= DATE('now', 'localtime')
            ORDER BY
                l.ano ASC,
                l.mes ASC,
                l.dia ASC
        """

        let rows = try Row.fetchAll(db, sql: sql)
        return mapRows(rows)
    }
    
    func listarLancamentosFuturosParaAgendar() async throws -> [LancamentoModel] {
        try await db.dbQueue.read { db in
            try self.listarLancamentosFuturosParaAgendar(db: db)
        }
    }
    
    private nonisolated func listarLancamentosFuturosParaAgendar(
        db: Database
    ) throws -> [LancamentoModel] {

        let sql = """
            SELECT
                l.*,
                c.id AS "c.id", c.uuid AS "c.uuid", c.nome AS "c.nome", c.saldo AS "c.saldo", c.currency_code AS "c.currency_code",
                ca.id AS "ca.id", ca.uuid AS "ca.uuid", ca.nome AS "ca.nome", ca.vencimento AS "ca.vencimento",
                ca.fechamento AS "ca.fechamento", ca.operadora AS "ca.operadora", ca.arquivado AS "ca.arquivado",
                ca.conta_uuid AS "ca.conta_uuid", ca.limite AS "ca.limite",
                cat.id AS "cat.id", cat.nome AS "cat.nome", cat.nomeKey AS "cat.nomeKey", cat.nomeSubcategoria AS "cat.nomeSubcategoria",
                cat.tipo AS "cat.tipo", cat.icone AS "cat.icone", cat.cor AS "cat.cor", cat.pai AS "cat.pai"
            FROM lancamento l
            LEFT JOIN conta c ON l.conta_uuid = c.uuid
            LEFT JOIN cartao ca ON l.cartao_uuid = ca.uuid
            LEFT JOIN categoria cat ON l.categoria = cat.id AND l.tipo = cat.tipo
            WHERE
                l.notificado = 0
            AND l.pago = 0
            AND DATE(
                    printf('%04d-%02d-%02d', l.ano, l.mes, l.dia)
                )
                BETWEEN
                    DATE('now', 'localtime')
                AND
                    DATE('now', 'localtime', '+1 month')
            ORDER BY
                l.ano ASC,
                l.mes ASC,
                l.dia ASC
        """

        let rows = try Row.fetchAll(db, sql: sql)
        return mapRows(rows)
    }
    
    private func listarLancamentosRecentes(db: Database) throws -> [LancamentoModel] {
        let sql = """
            SELECT
                l.*,
                c.id AS "c.id", c.uuid AS "c.uuid", c.nome AS "c.nome", c.saldo AS "c.saldo", c.currency_code AS "c.currency_code",
                ca.id AS "ca.id", ca.uuid AS "ca.uuid", ca.nome AS "ca.nome", ca.vencimento AS "ca.vencimento",
                ca.fechamento AS "ca.fechamento", ca.operadora AS "ca.operadora", ca.arquivado AS "ca.arquivado",
                ca.conta_uuid AS "ca.conta_uuid", ca.limite AS "ca.limite",
                cat.id AS "cat.id", cat.nome AS "cat.nome", cat.nomeKey AS "cat.nomeKey", cat.nomeSubcategoria AS "cat.nomeSubcategoria",
                cat.tipo AS "cat.tipo", cat.icone AS "cat.icone", cat.cor AS "cat.cor", cat.pai AS "cat.pai"
            FROM lancamento l
            LEFT JOIN conta c ON l.conta_uuid = c.uuid
            LEFT JOIN cartao ca ON l.cartao_uuid = ca.uuid
            LEFT JOIN categoria cat ON l.categoria = cat.id AND l.tipo = cat.tipo
            WHERE l.id IN (
                SELECT MIN(id) 
                FROM lancamento 
                GROUP BY uuid
            )
            ORDER BY                 
                l.dataCriacao DESC,
                l.id DESC
            LIMIT 10
        """
        
        let rows = try Row.fetchAll(db, sql: sql)
        return mapRows(rows)
    }


    func salvar(_ lancamento: LancamentoModel) async throws {
        try await db.dbQueue.write { db in
            try lancamento.insert(db)
        }
    }
    
    func editar(
        lancamento: LancamentoModel,
        escopo: EscopoEdicaoRecorrencia
    ) async throws {

        try await db.dbQueue.write { db in

            switch escopo {

            case .somenteEste:
                try editarUnico(lancamento, db: db)

            case .esteEProximos:
                try editarEsteEProximos(lancamento, db: db)

            case .todos:
                try editarTodos(lancamento, db: db)
            }
        }
    }
    
    private nonisolated func editarUnico(
        _ lancamento: LancamentoModel,
        db: Database
    ) throws {

        guard
            let id = lancamento.id,
            let antigo = try LancamentoModel
                .filter(LancamentoModel.Columns.id == id)
                .fetchOne(db)
        else {
            try lancamento.update(db)
            return
        }

        try aplicarDeltaSaldo(
            antigo: antigo,
            novo: lancamento,
            removendo: false,
            db: db
        )

        try lancamento.update(db)
    }
    
    private nonisolated func editarEsteEProximos(
        _ lancamentoBase: LancamentoModel,
        db: Database
    ) throws {

        let lancamentos = try LancamentoModel
            .filter(
                LancamentoModel.Columns.uuid == lancamentoBase.uuid &&
                (
                    LancamentoModel.Columns.ano > lancamentoBase.ano ||
                    (
                        LancamentoModel.Columns.ano == lancamentoBase.ano &&
                        LancamentoModel.Columns.mes >= lancamentoBase.mes
                    )
                )
            )
            .fetchAll(db)

        for antigo in lancamentos {

            var novo = antigo

            // 🔹 Campos que PODEM ser alterados
            novo.descricao = lancamentoBase.descricao
            novo.anotacao = lancamentoBase.anotacao
            novo.valor = lancamentoBase.valor
            novo.pagoRaw = lancamentoBase.pagoRaw
            novo.divididoRaw = lancamentoBase.divididoRaw
            novo.categoriaID = lancamentoBase.categoriaID
            novo.cartaoUuid = lancamentoBase.cartaoUuid
            novo.contaUuid = lancamentoBase.contaUuid

            try aplicarDeltaSaldo(
                antigo: antigo,
                novo: novo,
                removendo: false,
                db: db
            )

            try novo.update(db)
        }
    }
    
    private nonisolated func editarTodos(
        _ lancamentoBase: LancamentoModel,
        db: Database
    ) throws {

        let lancamentos = try LancamentoModel
            .filter(LancamentoModel.Columns.uuid == lancamentoBase.uuid)
            .fetchAll(db)

        for antigo in lancamentos {

            var novo = antigo

            novo.descricao = lancamentoBase.descricao
            novo.anotacao = lancamentoBase.anotacao
            novo.valor = lancamentoBase.valor
            novo.pagoRaw = lancamentoBase.pagoRaw
            novo.divididoRaw = lancamentoBase.divididoRaw
            novo.categoriaID = lancamentoBase.categoriaID
            novo.cartaoUuid = lancamentoBase.cartaoUuid
            novo.contaUuid = lancamentoBase.contaUuid

            try aplicarDeltaSaldo(
                antigo: antigo,
                novo: novo,
                removendo: false,
                db: db
            )

            try novo.update(db)
        }
    }
    
    func editar(_ lancamento: LancamentoModel) async throws {
        try await db.dbQueue.write { db in

            guard
                let id = lancamento.id,
                let antigo = try LancamentoModel
                    .filter(LancamentoModel.Columns.id == id)
                    .fetchOne(db)
            else {
                try lancamento.update(db)
                return
            }

            try aplicarDeltaSaldo(
                antigo: antigo,
                novo: lancamento,
                removendo: false,
                db: db
            )

            try lancamento.update(db)
        }
    }
    
    func remover(id: Int64, uuid: String) async throws {
        try await db.dbQueue.write { db in

            if let lancamento = try LancamentoModel
                .filter(
                    LancamentoModel.Columns.id == id &&
                    LancamentoModel.Columns.uuid == uuid
                )
                .fetchOne(db) {

                try aplicarDeltaSaldo(
                    antigo: lancamento,
                    novo: nil,
                    removendo: true,
                    db: db
                )
            }

            try LancamentoModel
                .filter(
                    LancamentoModel.Columns.id == id &&
                    LancamentoModel.Columns.uuid == uuid
                )
                .deleteAll(db)
        }
    }
    
    func removerRecorrentes(uuid: String) async throws {
       _ = try await db.dbQueue.write { db in
           
           let lancamentos = try LancamentoModel
                       .filter(LancamentoModel.Columns.uuid == uuid)
                       .fetchAll(db)

           for lancamento in lancamentos {
               try aplicarDeltaSaldo(
                antigo: lancamento,
                novo: nil,
                removendo: true,
                db: db
               )
           }
           
            try LancamentoModel
                .filter(LancamentoModel.Columns.uuid == uuid)
                .deleteAll(db)
        }
    }
    
    
    func removerEsteEProximos(
        uuid: String,
        mes: Int,
        ano: Int
    ) async throws {
        _ = try await db.dbQueue.write { db in
            
            let lancamentos = try LancamentoModel
                .filter(
                    LancamentoModel.Columns.uuid == uuid &&
                    (
                        LancamentoModel.Columns.ano > ano ||
                        (LancamentoModel.Columns.ano == ano &&
                         LancamentoModel.Columns.mes >= mes)
                    )
                )
                .fetchAll(db)

            for lancamento in lancamentos {
                try aplicarDeltaSaldo(
                    antigo: lancamento,
                    novo: nil,
                    removendo: true,
                    db: db
                )
            }
            
            try LancamentoModel
                .filter(
                    LancamentoModel.Columns.uuid == uuid &&
                    (
                        LancamentoModel.Columns.ano > ano ||
                        (LancamentoModel.Columns.ano == ano &&
                         LancamentoModel.Columns.mes >= mes)
                    )
                )
                .deleteAll(db)
        }
    }
    
    func togglePago(_ lancamentos: [LancamentoModel]) async throws {
        try await db.dbQueue.write { db in
            for var lancamento in lancamentos {

                let antigo = lancamento
                lancamento.pago.toggle()

                try aplicarDeltaSaldo(
                    antigo: antigo,
                    novo: lancamento,
                    removendo: false,
                    db: db
                )

                try lancamento.update(db)
            }
        }
    }
    
    // MARK: - Nova função pública para ViewModel
    func listarLancamentosDoAno(ano: Int) async throws -> [LancamentoModel] {
        do {
            return try await db.dbQueue.read { db in
                try self.listar(db: db, mes: nil, ano: ano)
            }
        } catch {
            print("Erro ao listar lançamentos:", error)
            return []
        }
    }
    
    private nonisolated func listar(
            db: Database,
            mes: Int? = nil,
            ano: Int? = nil
    ) throws -> [LancamentoModel] {
        
        var sql = """
                SELECT
                    l.*,
                    c.id AS "c.id", c.uuid AS "c.uuid", c.nome AS "c.nome", c.saldo AS "c.saldo", c.currency_code AS "c.currency_code",
                    ca.id AS "ca.id", ca.uuid AS "ca.uuid", ca.nome AS "ca.nome", ca.vencimento AS "ca.vencimento",
                    ca.fechamento AS "ca.fechamento", ca.operadora AS "ca.operadora", ca.arquivado AS "ca.arquivado",
                    ca.conta_uuid AS "ca.conta_uuid", ca.limite AS "ca.limite",
                    cat.id AS "cat.id", cat.nome AS "cat.nome", cat.nomeKey AS "cat.nomeKey", cat.nomeSubcategoria AS "cat.nomeSubcategoria",
                    cat.tipo AS "cat.tipo", cat.icone AS "cat.icone", cat.cor AS "cat.cor", cat.pai AS "cat.pai"
                FROM lancamento l
                LEFT JOIN conta c ON l.conta_uuid = c.uuid
                LEFT JOIN cartao ca ON l.cartao_uuid = ca.uuid
                LEFT JOIN categoria cat ON l.categoria = cat.id AND l.tipo = cat.tipo
            """
        
        var arguments: [DatabaseValueConvertible] = []
        
        if let mes, let ano {
            sql += " WHERE l.mes = ? AND l.ano = ?"
            arguments.append(contentsOf: [mes, ano])
        } else if let ano {
            sql += " WHERE l.ano = ?"
            arguments.append(ano)
        }
        
        sql += " ORDER BY l.ano DESC, l.mes DESC, l.dia DESC"
        
        let rows = try Row.fetchAll(
            db,
            sql: sql,
            arguments: StatementArguments(arguments)
        )
        
        return mapRows(rows)
    }
    
    private nonisolated func mapRows(_ rows: [Row]) -> [LancamentoModel] {
        rows.map { row in
            let conta = row["c.id"] != nil ? ContaModel(
                id: row["c.id"],
                uuid: row["c.uuid"],
                nome: row["c.nome"],
                saldo: row["c.saldo"],
                currencyCode: row["c.currency_code"]
            ) : nil

            let cartao = row["ca.id"] != nil ? CartaoModel(
                id: row["ca.id"],
                uuid: row["ca.uuid"],
                nome: row["ca.nome"],
                vencimento: row["ca.vencimento"],
                fechamento: row["ca.fechamento"],
                operadora: row["ca.operadora"],
                arquivado: row["ca.arquivado"],
                contaUuid: row["ca.conta_uuid"],
                limite: row["ca.limite"],
                conta: nil
            ) : nil

            let categoria = row["cat.id"] != nil ? CategoriaModel(
                id: row["cat.id"],
                nomeRaw: row["cat.nome"],
                nomeKey: row["cat.nomeKey"],
                nomeSubcategoria: row["cat.nomeSubcategoria"],
                tipo: row["cat.tipo"],
                icone: row["cat.icone"],
                cor: row["cat.cor"],
                pai: row["cat.pai"]
            ) : nil

            return LancamentoModel(
                id: row["id"],
                uuid: row["uuid"],
                descricao: row["notas"],
                anotacao: row["anotacao"],
                tipo: row["tipo"],
                transferenciaRaw: row["transferencia"],
                dia: row["dia"],
                mes: row["mes"],
                ano: row["ano"],
                diaCompra: row["diaCompra"],
                mesCompra: row["mesCompra"],
                anoCompra: row["anoCompra"],
                categoriaID: row["categoria"],
                cartaoUuid: row["cartao_uuid"],
                recorrente: row["recorrente"],
                parcelas: row["parcelas"],
                parcelaMes: row["parcelaMes"],
                valor: row["valor"],
                pagoRaw: row["pago"],
                divididoRaw: row["dividido"],
                contaUuid: row["conta_uuid"],
                dataCriacao: row["dataCriacao"],
                notificacaoLidaRaw: row["notificado"] as Int? ?? 0,
                currencyCode: row["currency_code"],
                categoria: categoria,
                cartao: cartao,
                conta: conta
            )
        }
    }
}

protocol LancamentoRepositoryProtocol {
    func observeLancamentos(
        mes: Int?,
        ano: Int?,
        onChange: @escaping ([LancamentoModel]) -> Void
    ) -> AnyDatabaseCancellable
    func observeLancamentosParaNotificacao(
        onChange: @escaping ([LancamentoModel]) -> Void
    ) -> AnyDatabaseCancellable
    func salvar(_ lancamento: LancamentoModel) async throws
    func editar(_ lancamento: LancamentoModel) async throws
    func remover(id: Int64, uuid: String) async throws
    func removerRecorrentes(uuid: String) async throws
}

// MARK: - Saldo helpers

private extension LancamentoRepository {

    private nonisolated func atualizarSaldoConta(
        contaUuid: String,
        delta: Decimal,
        db: Database
    ) throws {
        guard delta != 0 else { return }

        try db.execute(
            sql: """
            UPDATE conta
            SET saldo = saldo + ?
            WHERE uuid = ?
            """,
            arguments: [delta, contaUuid]
        )
    }

    private nonisolated func aplicarDeltaSaldo(
        antigo: LancamentoModel,
        novo: LancamentoModel?,
        removendo: Bool,
        db: Database
    ) throws {

        let estavaPago = antigo.pago
        let valorAnterior = antigo.valorComSinal

        var delta: Decimal = 0

        if removendo {
            if estavaPago {
                delta = -valorAnterior
            }
        } else if let novo {

            let estaPagoAgora = novo.pago
            let valorNovo = novo.valorComSinal

            switch (estavaPago, estaPagoAgora) {
            case (false, true):
                delta = valorNovo

            case (true, false):
                delta = -valorAnterior

            case (true, true):
                delta = valorNovo - valorAnterior

            default:
                break
            }
        }

        try atualizarSaldoConta(
            contaUuid: antigo.contaUuid,
            delta: delta,
            db: db
        )
    }
}


