//
//  LancamentoRepository.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import GRDB

final class LancamentoRepository : LancamentoRepositoryProtocol{
        
    fileprivate let db: AppDatabase
    
    init (db: AppDatabase = .shared){
        self.db = db
    }
    
    func observeLancamentos(
        onChange: @escaping ([LancamentoModel]) -> Void
    ) -> AnyDatabaseCancellable {

        let observation = ValueObservation.tracking { db in
            try self.listar(db: db)
        }
        
        return observation.start(
            in: db.dbQueue,
            onError: { print("Erro DB:", $0) },
            onChange: onChange
        )
    }

    func salvar(_ lancamento: inout LancamentoModel) throws {
        try db.dbQueue.write { db in
            try lancamento.insert(db)
        }
    }
    
    func editar(_ lancamento: LancamentoModel) throws {
        try db.dbQueue.write { db in
            try lancamento.update(db)
        }
    }
    
    func remover(id: Int64, uuid: String) throws {
       _ =  try db.dbQueue.write { db in
            try LancamentoModel
                .filter(
                    LancamentoModel.Columns.id == id &&
                    LancamentoModel.Columns.uuid == uuid
                )
                .deleteAll(db)
        }
    }
    
    func limparDados() throws {
       _ =  try db.dbQueue.write { db in
            try LancamentoModel.deleteAll(db)
        }
    }
    
    func listar() throws -> [LancamentoModel] {
        try db.dbQueue.read { db in
            try listar(db: db)
        }
    }

    
    private func listar(db: Database) throws -> [LancamentoModel] {
        let rows = try Row.fetchAll(db, sql: """
                SELECT
                    l.*,
                    c.id AS "c.id", c.uuid AS "c.uuid", c.nome AS "c.nome", c.saldo AS "c.saldo", c.currency_code AS "c.currency_code",
                    ca.id AS "ca.id", ca.uuid AS "ca.uuid", ca.nome AS "ca.nome", ca.vencimento AS "ca.vencimento",
                    ca.fechamento AS "ca.fechamento", ca.operadora AS "ca.operadora", ca.arquivado AS "ca.arquivado",
                    ca.conta_uuid AS "ca.conta_uuid", ca.limite AS "ca.limite",
                    cat.id AS "cat.id", cat.nome AS "cat.nome", cat.nomeSubcategoria AS "cat.nomeSubcategoria",
                    cat.tipo AS "cat.tipo", cat.icone AS "cat.icone", cat.cor AS "cat.cor", cat.pai AS "cat.pai"
                FROM lancamento l
                LEFT JOIN conta c ON l.conta_uuid = c.uuid
                LEFT JOIN cartao ca ON l.cartao_uuid = ca.uuid
                LEFT JOIN categoria cat ON l.categoria = cat.id AND l.tipo = cat.tipo
                ORDER BY l.ano DESC, l.mes DESC, l.dia DESC
            """)
            
        return rows.map { row in
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
                nome: row["cat.nome"],
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
                transferencia: row["transferencia"],
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
                pago: row["pago"],
                dividido: row["dividido"],
                contaUuid: row["conta_uuid"],             
                notificado: row["notificado"],
                dataCriacao: row["dataCriacao"],
                categoria: categoria,
                cartao: cartao,
                conta: conta
            )
        }
    }
    
    func consultarPorUuid(_ uuid: String) throws -> [LancamentoModel] {
        try db.dbQueue.read { db in
            try LancamentoModel
                .filter(LancamentoModel.Columns.uuid == uuid)
                .fetchAll(db)
        }
    }
}

protocol LancamentoRepositoryProtocol {
    
    func observeLancamentos(
        onChange: @escaping (
            [LancamentoModel]
        ) -> Void
    ) -> AnyDatabaseCancellable
    func salvar(_ lancamento: inout LancamentoModel) throws
    func editar(_ lancamento: LancamentoModel) throws
    func remover(id: Int64, uuid: String) throws
    func limparDados() throws
    func listar() throws -> [LancamentoModel]
    func consultarPorUuid(_ uuid: String) throws -> [LancamentoModel]
}
