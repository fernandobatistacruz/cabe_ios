import GRDB
import UIKit
import Foundation
import SwiftUI

extension AppDatabase {

    static func makeMigrator(defaultCurrencyCode: String) -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.eraseDatabaseOnSchemaChange = false
      
        migrator.registerMigration("baseline_v23") { _ in }
        
        migrator.registerMigration("create_schema_v23") { db in

            let exists = try db.tableExists("conta")
                        guard !exists else { return }

            try db.create(table: "conta") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("uuid", .text).notNull()
                t.column("nome", .text).notNull()
                t.column("saldo", .double).notNull()
            }

            try db.create(table: "cartao") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("uuid", .text).notNull()
                t.column("nome", .text).notNull()
                t.column("vencimento", .integer)
                t.column("fechamento", .integer)
                t.column("operadora", .integer)
                t.column("arquivado", .integer)
                t.column("conta_uuid", .text).notNull()
                t.column("limite", .double)
            }

            try db.create(table: "categoria") { t in
                t.column("id", .integer).notNull()
                t.column("nome", .text).notNull()
                t.column("nomeSubcategoria", .text)
                t.column("tipo", .integer).notNull()
                t.column("icone", .integer).notNull()
                t.column("cor", .integer).notNull()
                t.column("pai", .integer)
                t.primaryKey(["id", "tipo"], onConflict: .replace)
            }

            try db.create(table: "lancamento") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("uuid", .text)
                t.column("tipo", .integer)
                t.column("dia", .integer)
                t.column("mes", .integer)
                t.column("ano", .integer)
                t.column("diaCompra", .integer)
                t.column("mesCompra", .integer)
                t.column("anoCompra", .integer)
                t.column("categoria", .integer)
                t.column("recorrente", .integer)
                t.column("parcelas", .integer)
                t.column("parcelaMes", .text)
                t.column("valor", .double)
                t.column("cartao_uuid", .text)
                t.column("descricao", .text)
                t.column("notas", .text)
                t.column("anotacao", .text)
                t.column("pago", .integer)
                t.column("transferencia", .integer)
                t.column("dividido", .integer)
                t.column("conta_uuid", .text)
                t.column("dataCriacao", .text)
                t.column("notificado", .integer)
            }
        }
        
        migrator.registerMigration("addCurrencyCodeToConta") { db in
            try db.alter(table: "conta") { t in
                t.add(column: "currency_code", .text)
                    .notNull()
                    .defaults(to: defaultCurrencyCode)
            }
        }
        
        migrator.registerMigration("addCurrencyCodeToLancamento") { db in
            try db.alter(table: "lancamento") { t in
                t.add(column: "currency_code", .text)
                    .notNull()
                    .defaults(to: defaultCurrencyCode)
            }
        }
         
        migrator.registerMigration("insertContaInicial") { db in
            let count = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM conta"
            ) ?? 0

            guard count == 0 else { return }

            try ContaModel(
                id: nil,
                uuid: UUID().uuidString,
                nome: NSLocalizedString("Conta Inicial", comment: ""),
                saldo: 0,
                currencyCode: defaultCurrencyCode
            ).insert(db)
        }
        
        migrator.registerMigration("dropFavoritosTable") { db in
            try db.execute(sql: "DROP TABLE IF EXISTS favoritos")
        }
        
        migrator.registerMigration("addNomeKeyToCategoria") { db in
            try db.alter(table: "categoria") { t in
                t.add(column: "nomeKey", .text)
            }
        }       
        
        migrator.registerMigration("v2_categoria_rgba") { db in
            try db.alter(table: "categoria") { t in
                t.add(column: "red", .double).notNull().defaults(to: 0)
                t.add(column: "green", .double).notNull().defaults(to: 0)
                t.add(column: "blue", .double).notNull().defaults(to: 0)
                t.add(column: "opacity", .double).notNull().defaults(to: 1)
            }
            
            // Paleta antiga convertida para RGBA puro
            let palette: [(Double, Double, Double, Double)] = [
                // 0  - .green
                (0.2039, 0.7804, 0.3490, 1.0),
                // 1  - .green.opacity(0.8)
                (0.2039, 0.7804, 0.3490, 0.8),
                // 2  - .teal
                (0.0000, 0.7373, 0.8314, 1.0),
                // 3  - .cyan
                (0.0000, 0.8000, 1.0000, 1.0),
                // 4  - .yellow
                (1.0000, 0.8000, 0.0000, 1.0),
                // 5  - .yellow.opacity(0.8)
                (1.0000, 0.8000, 0.0000, 0.8),
                // 6  - .yellow.opacity(0.6)
                (1.0000, 0.8000, 0.0000, 0.6),
                // 7  - .orange
                (1.0000, 0.5843, 0.0000, 1.0),
                // 8  - .orange.opacity(0.8)
                (1.0000, 0.5843, 0.0000, 0.8),
                // 9  - .orange.opacity(0.5)
                (1.0000, 0.5843, 0.0000, 0.5),
                // 10 - .pink
                (1.0000, 0.1765, 0.3333, 1.0),
                // 11 - .red
                (1.0000, 0.2314, 0.1882, 1.0),
                // 12 - .red.opacity(0.8)
                (1.0000, 0.2314, 0.1882, 0.8),
                // 13 - .pink.opacity(0.8)
                (1.0000, 0.1765, 0.3333, 0.8),
                // 14 - .blue
                (0.0000, 0.4784, 1.0000, 1.0),
                // 15 - .blue.opacity(0.8)
                (0.0000, 0.4784, 1.0000, 0.8),
                // 16 - .blue.opacity(0.6)
                (0.0000, 0.4784, 1.0000, 0.6),
                // 17 - .cyan.opacity(0.6)
                (0.0000, 0.8000, 1.0000, 0.6),
                // 18 - .indigo
                (0.3451, 0.3373, 0.8392, 1.0),
                // 19 - .teal.opacity(0.6)
                (0.0000, 0.7373, 0.8314, 0.6),
                // 20 - .indigo.opacity(0.6)
                (0.3451, 0.3373, 0.8392, 0.6),
                // 21 - .pink.opacity(0.4)
                (1.0000, 0.1765, 0.3333, 0.4),
                // 22 - .purple
                (0.6863, 0.3216, 0.8706, 1.0),
                // 23 - .purple.opacity(0.8)
                (0.6863, 0.3216, 0.8706, 0.8),
                // 24 - .purple.opacity(0.6)
                (0.6863, 0.3216, 0.8706, 0.6),
                // 25 - .purple.opacity(0.5)
                (0.6863, 0.3216, 0.8706, 0.5),
                // 26 - .gray
                (0.5569, 0.5569, 0.5765, 1.0),
                // 27 - .gray.opacity(0.6)
                (0.5569, 0.5569, 0.5765, 0.6),
                // 28 - .mint
                (0.0000, 0.7843, 0.6667, 1.0),
                // 29 - .brown
                (0.6353, 0.5176, 0.3686, 1.0),
            ]
            
            // Migrar dados
            let rows = try Row.fetchAll(db, sql: "SELECT id, cor FROM categoria")
            
            for row in rows {
                let id: Int64 = row["id"]
                let corIndex: Int = row["cor"]
                
                let rgba = palette.indices.contains(corIndex)
                ? palette[corIndex]
                : (0.5, 0.5, 0.5, 1) // default gray
                
                try db.execute(
                    sql: """
                    UPDATE categoria
                    SET red = ?, green = ?, blue = ?, opacity = ?
                    WHERE id = ?
                    """,
                    arguments: [rgba.0, rgba.1, rgba.2, rgba.3, id]
                )
            }
            
            // Remove coluna antiga
            try db.alter(table: "categoria") { t in
                t.drop(column: "cor")
            }
        }
        
        migrator.registerMigration("seedCategoriasPadrao") { db in
            let count = try CategoriaModel.fetchCount(db)
            guard count == 0 else { return }

            let categoriasPadrao: [CategoriaModel] = [

                // Receitas
                .defaultCategoria(id: 0, nomeKey: "category.estorno", tipo: 1, iconeRaw: 5, corIndex: 0),
                .defaultCategoria(id: 1, nomeKey: "category.salario", tipo: 1, iconeRaw: 5, corIndex: 0),
                .defaultCategoria(id: 2, nomeKey: "category.premio", tipo: 1, iconeRaw: 5, corIndex: 0),
                .defaultCategoria(id: 3, nomeKey: "category.investimento", tipo: 1, iconeRaw: 2, corIndex: 0),
                .defaultCategoria(id: 4, nomeKey: "category.aluguel", tipo: 1, iconeRaw: 3, corIndex: 0),
                .defaultCategoria(id: 5, nomeKey: "category.participacao_resultados", tipo: 1, iconeRaw: 5, corIndex: 0),
                .defaultCategoria(id: 6, nomeKey: "category.decimo", tipo: 1, iconeRaw: 5, corIndex: 0),

                // Despesas
                .defaultCategoria(id: 1, nomeKey: "category.combustivel", tipo: 2, iconeRaw: 4, corIndex: 1),
                .defaultCategoria(id: 2, nomeKey: "category.financiamento", tipo: 2, iconeRaw: 5, corIndex: 2),
                .defaultCategoria(id: 3, nomeKey: "category.energia_eletrica", tipo: 2, iconeRaw: 6, corIndex: 3),
                .defaultCategoria(id: 4, nomeKey: "category.internet", tipo: 2, iconeRaw: 7, corIndex: 4),
                .defaultCategoria(id: 5, nomeKey: "category.seguro", tipo: 2, iconeRaw: 8, corIndex: 5),
                .defaultCategoria(id: 6, nomeKey: "category.veiculo", tipo: 2, iconeRaw: 9, corIndex: 6),
                .defaultCategoria(id: 7, nomeKey: "category.condominio", tipo: 2, iconeRaw: 3, corIndex: 7),
                .defaultCategoria(id: 8, nomeKey: "category.alimentacao", tipo: 2, iconeRaw: 10, corIndex: 8),
                .defaultCategoria(id: 9, nomeKey: "category.telefonia", tipo: 2, iconeRaw: 11, corIndex: 9),
                .defaultCategoria(id: 10, nomeKey: "category.lazer_hobby", tipo: 2, iconeRaw: 12, corIndex: 0),
                .defaultCategoria(id: 11, nomeKey: "category.barbearia_salao", tipo: 2, iconeRaw: 13, corIndex: 10),
                .defaultCategoria(id: 12, nomeKey: "category.vestuario", tipo: 2, iconeRaw: 14, corIndex: 11),
                .defaultCategoria(id: 13, nomeKey: "category.casa", tipo: 2, iconeRaw: 15, corIndex: 12),
                .defaultCategoria(id: 14, nomeKey: "category.saude", tipo: 2, iconeRaw: 16, corIndex: 13),
                .defaultCategoria(id: 15, nomeKey: "category.diarista", tipo: 2, iconeRaw: 17, corIndex: 14),
                .defaultCategoria(id: 16, nomeKey: "category.atividade_fisica", tipo: 2, iconeRaw: 18, corIndex: 15),
                .defaultCategoria(id: 17, nomeKey: "category.transporte", tipo: 2, iconeRaw: 19, corIndex: 16),
                .defaultCategoria(id: 18, nomeKey: "category.refeicao", tipo: 2, iconeRaw: 20, corIndex: 17),
                .defaultCategoria(id: 19, nomeKey: "category.imposto_tarifa", tipo: 2, iconeRaw: 21, corIndex: 18),
                .defaultCategoria(id: 20, nomeKey: "category.presente", tipo: 2, iconeRaw: 22, corIndex: 19),
                .defaultCategoria(id: 21, nomeKey: "category.eletronico", tipo: 2, iconeRaw: 23, corIndex: 20),
                .defaultCategoria(id: 22, nomeKey: "category.eletrodomestico", tipo: 2, iconeRaw: 24, corIndex: 21),
                .defaultCategoria(id: 23, nomeKey: "category.streaming_tv", tipo: 2, iconeRaw: 25, corIndex: 22),
                .defaultCategoria(id: 24, nomeKey: "category.doacao", tipo: 2, iconeRaw: 26, corIndex: 23),
                .defaultCategoria(id: 25, nomeKey: "category.estetica", tipo: 2, iconeRaw: 27, corIndex: 24),
                .defaultCategoria(id: 26, nomeKey: "category.educacao", tipo: 2, iconeRaw: 28, corIndex: 25),
                .defaultCategoria(id: 27, nomeKey: "category.agua_esgoto", tipo: 2, iconeRaw: 29, corIndex: 26),
                .defaultCategoria(id: 28, nomeKey: "category.pets", tipo: 2, iconeRaw: 30, corIndex: 27),
                .defaultCategoria(id: 29, nomeKey: "category.cuidados_pessoais", tipo: 2, iconeRaw: 31, corIndex: 28)
            ]

            for cat in categoriasPadrao {
                try cat.insert(db)
            }
        }
        
        migrator.registerMigration("addIndexLancamentoNotas") { db in
            try db.create(
                index: "idx_lancamento_notas",
                on: "lancamento",
                columns: ["notas"],
                ifNotExists: true
            )
        }
        
        migrator.registerMigration("fixNullCartaoUuid") { db in
            try db.execute(
                sql: """
                    UPDATE lancamento
                    SET cartao_uuid = ''
                    WHERE cartao_uuid IS NULL
                """
            )
        }
        
        return migrator
    }
}
