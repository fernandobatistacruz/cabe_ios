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
                l.id DESC,        
                l.dataCriacao DESC                
            LIMIT 10
        """
        
        let rows = try Row.fetchAll(db, sql: sql)
        return mapRows(rows)
    }
    
    func existeLancamentoParaConta(contaUuid: String) async throws -> Bool {
        try await db.dbQueue.read { db in
            try Bool.fetchOne(
                db,
                sql: """
                    SELECT EXISTS(
                        SELECT 1
                        FROM lancamento
                        WHERE conta_uuid = ?
                        LIMIT 1
                    )
                """,
                arguments: [contaUuid]
            ) ?? false
        }
    }
    
    func existeLancamentoParaCartao(cartaoUuid: String) async throws -> Bool {
        try await db.dbQueue.read { db in
            try Bool.fetchOne(
                db,
                sql: """
                    SELECT EXISTS(
                        SELECT 1
                        FROM lancamento
                        WHERE cartao_uuid = ?
                        LIMIT 1
                    )
                """,
                arguments: [cartaoUuid]
            ) ?? false
        }
    }
    
    func existeLancamentoParaCategoria(id: Int64, tipo: Int) async throws -> Bool {
        try await db.dbQueue.read { db in
            try Bool.fetchOne(
                db,
                sql: """
                    SELECT EXISTS(
                        SELECT 1
                        FROM lancamento
                        WHERE categoria = ? AND tipo = ?
                        LIMIT 1
                    )
                """,
                arguments: [id, tipo]
            ) ?? false
        }
    }
    
    func salvar(_ lancamento: LancamentoModel) async throws {
        try await db.dbQueue.write { db in

            // 1. Insere o lançamento
            try lancamento.insert(db)

            // 2. Se já nasce pago, impacta o saldo
            if lancamento.pago {
                try atualizarSaldoConta(
                    contaUuid: lancamento.contaUuid,
                    delta: lancamento.valorComSinal,
                    db: db
                )
            }
        }
    }
    
    func editar(
        antigo: LancamentoModel,
        novo: LancamentoModel,
        escopo: EscopoEdicaoRecorrencia
    ) async throws {

        try await db.dbQueue.write { db in

            switch escopo {

            case .somenteEste:
                try editarUnico(
                    antigo: antigo,
                    novo: novo,
                    db: db
                )

            case .esteEProximos:
                try editarEsteEProximos(
                    antigo: antigo,
                    novo: novo,
                    db: db
                )

            case .todos:
                try editarTodos(
                    antigo: antigo,
                    novo: novo,
                    db: db
                )
            }
        }
    }
    
    private nonisolated func editarUnico(
        antigo: LancamentoModel,
        novo: LancamentoModel,
        db: Database
    ) throws {
        
        try novo.update(db)
        
        try aplicarDeltaSaldo(
            antigo: antigo,
            novo: novo,
            removendo: false,
            db: db
        )
    }
    
    private nonisolated func editarEsteEProximos(
        antigo: LancamentoModel,
        novo: LancamentoModel,
        db: Database
    ) throws {
        
        let lancamentos = try LancamentoModel
            .filter(
                LancamentoModel.Columns.uuid == antigo.uuid &&
                (
                    LancamentoModel.Columns.ano > antigo.ano ||
                    (
                        LancamentoModel.Columns.ano == antigo.ano &&
                        LancamentoModel.Columns.mes >= antigo.mes
                    )
                )
                && LancamentoModel.Columns.id >= antigo.id
            )
            .fetchAll(db)
        
        let calendar = Calendar.current
        var dataVencimento = novo.dataVencimento

        for lancamento in lancamentos {
            
            var atualizado = lancamento
            
            atualizado.dia = calendar.component(.day, from: dataVencimento)
            atualizado.mes = calendar.component(.month, from: dataVencimento)
            atualizado.ano = calendar.component(.year, from: dataVencimento)
            atualizado.diaCompra = novo.diaCompra
            atualizado.mesCompra = novo.mesCompra
            atualizado.anoCompra = novo.anoCompra
            atualizado.descricao = novo.descricao
            atualizado.anotacao = novo.anotacao
            atualizado.valor = novo.valor
            atualizado.pagoRaw = novo.pagoRaw
            atualizado.divididoRaw = novo.divididoRaw
            atualizado.categoriaID = novo.categoriaID
            atualizado.cartaoUuid = novo.cartaoUuid
            atualizado.contaUuid = novo.contaUuid
            atualizado.cartao = novo.cartao
                        
            try aplicarDeltaSaldo(
                antigo: antigo,
                novo: atualizado,
                removendo: false,
                db: db
            )
            
            try atualizado.update(db)
            
            switch atualizado.tipoRecorrente {
            case .nunca, .parcelado:
                break
            case .mensal:
                dataVencimento = calendar.date(byAdding: .month, value: 1, to: dataVencimento)!
            case .quinzenal:
                dataVencimento = calendar.date(byAdding: .day, value: 14, to: dataVencimento)!
            case .semanal:
                dataVencimento = calendar.date(byAdding: .day, value: 7, to: dataVencimento)!
            }
        }
    }
    
    private nonisolated func editarTodos(
        antigo: LancamentoModel,
        novo: LancamentoModel,
        db: Database
    ) throws {

        let lancamentos = try LancamentoModel
            .filter(LancamentoModel.Columns.uuid == antigo.uuid)
            .fetchAll(db)

        for lancamento in lancamentos {

            var atualizado = lancamento
            
            atualizado.diaCompra = novo.diaCompra
            atualizado.mesCompra = novo.mesCompra
            atualizado.anoCompra = novo.anoCompra
            atualizado.descricao = novo.descricao
            atualizado.anotacao = novo.anotacao
            atualizado.valor = novo.valor
            atualizado.pagoRaw = novo.pagoRaw
            atualizado.divididoRaw = novo.divididoRaw
            atualizado.categoriaID = novo.categoriaID
            atualizado.cartaoUuid = novo.cartaoUuid
            atualizado.contaUuid = novo.contaUuid
            atualizado.cartao = novo.cartao

            try aplicarDeltaSaldo(
                antigo: antigo,
                novo: atualizado,
                removendo: false,
                db: db
            )

            try atualizado.update(db)
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
    
    func listarLancamentosAteAno(_ ano: Int) async throws -> [LancamentoModel] {
        try await db.dbQueue.read { db in
            try self.listarAteAno(db: db, ano: ano)
        }
    }
    
    private nonisolated func listarAteAno(
        db: Database,
        ano: Int
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
            WHERE l.ano <= ?
            ORDER BY l.ano DESC, l.mes DESC, l.dia DESC, l.id DESC
        """

        let rows = try Row.fetchAll(db, sql: sql, arguments: [ano])
        return mapRows(rows)
    }
    
    func buscarLancamentos(
        texto: String,
        limit: Int = 50
    ) async throws -> [LancamentoModel] {

        guard texto.count >= 2 else { return [] }

        let termo = "%\(texto.lowercased())%"

        return try await db.dbQueue.read { db in
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
                WHERE lower(l.notas) LIKE ?
                AND l.id IN (
                    SELECT MIN(id)
                    FROM lancamento
                    WHERE lower(notas) LIKE ?
                    GROUP BY uuid
                )
                ORDER BY 
                    l.id DESC,
                    l.dataCriacao DESC
                LIMIT ?
            """

            let rows = try Row.fetchAll(
                db,
                sql: sql,
                arguments: [termo, termo, limit]
            )

            return mapRows(rows)
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
        
        sql += " ORDER BY l.ano DESC, l.mes DESC, l.dia DESC, l.id DESC"
        
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
                arquivadoRaw: row["ca.arquivado"],
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
                cartaoUuid: row["cartao_uuid"] ?? "",
                recorrente: row["recorrente"],
                parcelas: row["parcelas"],
                parcelaMes: row["parcelaMes"],
                valor: row["valor"],
                pagoRaw: row["pago"],
                divididoRaw: row["dividido"],
                contaUuid: row["conta_uuid"] ?? "" ,
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
        let valorAntigo = antigo.valorParaSaldo
        let contaAntiga = try contaImpactada(lancamento: antigo)

        // 🗑 Remoção
        if removendo {
            if estavaPago {
                try atualizarSaldoConta(
                    contaUuid: contaAntiga,
                    delta: -valorAntigo,
                    db: db
                )
            }
            return
        }

        guard let novo else { return }

        let estaPagoAgora = novo.pago
        let valorNovo = novo.valorParaSaldo
        let contaNova = try contaImpactada(lancamento: novo)

        // 🔄 Caso 1: estava pago → agora não pago
        if estavaPago && !estaPagoAgora {
            try atualizarSaldoConta(
                contaUuid: contaAntiga,
                delta: -valorAntigo,
                db: db
            )
            return
        }

        // 🔄 Caso 2: não estava pago → agora pago
        if !estavaPago && estaPagoAgora {
            try atualizarSaldoConta(
                contaUuid: contaNova,
                delta: valorNovo,
                db: db
            )
            return
        }

        // 🔄 Caso 3: pago → pago
        if estavaPago && estaPagoAgora {

            // Mudou a conta (ou cartão)
            if contaAntiga != contaNova {
                // estorna da antiga
                try atualizarSaldoConta(
                    contaUuid: contaAntiga,
                    delta: -valorAntigo,
                    db: db
                )

                // aplica na nova
                try atualizarSaldoConta(
                    contaUuid: contaNova,
                    delta: valorNovo,
                    db: db
                )
            } else {
                // mesma conta → só ajusta diferença
                let delta = valorNovo - valorAntigo
                if delta != 0 {
                    try atualizarSaldoConta(
                        contaUuid: contaNova,
                        delta: delta,
                        db: db
                    )
                }
            }
        }
    }
    
    private nonisolated func contaImpactada(lancamento: LancamentoModel) throws -> String {
        
        var contaUuid = lancamento.contaUuid
        
        if lancamento.cartao != nil {
            contaUuid = lancamento.cartao?.contaUuid ?? ""
        }
        
        return contaUuid
    }
}


