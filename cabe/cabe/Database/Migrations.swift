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

                // MARK: - Receitas (corIndex 0 → green)
                CategoriaModel(id: 0, nomeRaw: "", nomeKey: "category.estorno", nomeSubcategoria: nil, tipo: 1, iconeRaw: 5, red: 0.2039, green: 0.7804, blue: 0.3490, opacity: 1.0, pai: nil),
                CategoriaModel(id: 1, nomeRaw: "", nomeKey: "category.salario", nomeSubcategoria: nil, tipo: 1, iconeRaw: 5, red: 0.2039, green: 0.7804, blue: 0.3490, opacity: 1.0, pai: nil),
                CategoriaModel(id: 2, nomeRaw: "", nomeKey: "category.premio", nomeSubcategoria: nil, tipo: 1, iconeRaw: 5, red: 0.2039, green: 0.7804, blue: 0.3490, opacity: 1.0, pai: nil),
                CategoriaModel(id: 3, nomeRaw: "", nomeKey: "category.investimento", nomeSubcategoria: nil, tipo: 1, iconeRaw: 2, red: 0.2039, green: 0.7804, blue: 0.3490, opacity: 1.0, pai: nil),
                CategoriaModel(id: 4, nomeRaw: "", nomeKey: "category.aluguel", nomeSubcategoria: nil, tipo: 1, iconeRaw: 3, red: 0.2039, green: 0.7804, blue: 0.3490, opacity: 1.0, pai: nil),
                CategoriaModel(id: 5, nomeRaw: "", nomeKey: "category.participacao_resultados", nomeSubcategoria: nil, tipo: 1, iconeRaw: 5, red: 0.2039, green: 0.7804, blue: 0.3490, opacity: 1.0, pai: nil),
                CategoriaModel(id: 6, nomeRaw: "", nomeKey: "category.decimo", nomeSubcategoria: nil, tipo: 1, iconeRaw: 5, red: 0.2039, green: 0.7804, blue: 0.3490, opacity: 1.0, pai: nil),

                // MARK: - Despesas
                CategoriaModel(id: 1, nomeRaw: "", nomeKey: "category.combustivel", nomeSubcategoria: nil, tipo: 2, iconeRaw: 4, red: 0.2039, green: 0.7804, blue: 0.3490, opacity: 0.8),
                CategoriaModel(id: 2, nomeRaw: "", nomeKey: "category.financiamento", nomeSubcategoria: nil, tipo: 2, iconeRaw: 5, red: 0.0000, green: 0.7373, blue: 0.8314, opacity: 1.0),
                CategoriaModel(id: 3, nomeRaw: "", nomeKey: "category.energia_eletrica", nomeSubcategoria: nil, tipo: 2, iconeRaw: 6, red: 0.0000, green: 0.8000, blue: 1.0000, opacity: 1.0),
                CategoriaModel(id: 4, nomeRaw: "", nomeKey: "category.internet", nomeSubcategoria: nil, tipo: 2, iconeRaw: 7, red: 1.0000, green: 0.8000, blue: 0.0000, opacity: 1.0),
                CategoriaModel(id: 5, nomeRaw: "", nomeKey: "category.seguro", nomeSubcategoria: nil, tipo: 2, iconeRaw: 8, red: 1.0000, green: 0.8000, blue: 0.0000, opacity: 0.8),
                CategoriaModel(id: 6, nomeRaw: "", nomeKey: "category.veiculo", nomeSubcategoria: nil, tipo: 2, iconeRaw: 9, red: 1.0000, green: 0.8000, blue: 0.0000, opacity: 0.6),
                CategoriaModel(id: 7, nomeRaw: "", nomeKey: "category.condominio", nomeSubcategoria: nil, tipo: 2, iconeRaw: 3, red: 1.0000, green: 0.5843, blue: 0.0000, opacity: 1.0),
                CategoriaModel(id: 8, nomeRaw: "", nomeKey: "category.alimentacao", nomeSubcategoria: nil, tipo: 2, iconeRaw: 10, red: 1.0000, green: 0.5843, blue: 0.0000, opacity: 0.8),
                CategoriaModel(id: 9, nomeRaw: "", nomeKey: "category.telefonia", nomeSubcategoria: nil, tipo: 2, iconeRaw: 11, red: 1.0000, green: 0.5843, blue: 0.0000, opacity: 0.5),
                CategoriaModel(id: 10, nomeRaw: "", nomeKey: "category.lazer_hobby", nomeSubcategoria: nil, tipo: 2, iconeRaw: 12, red: 0.2039, green: 0.7804, blue: 0.3490, opacity: 1.0),
                CategoriaModel(id: 11, nomeRaw: "", nomeKey: "category.barbearia_salao", nomeSubcategoria: nil, tipo: 2, iconeRaw: 13, red: 1.0000, green: 0.1765, blue: 0.3333, opacity: 1.0),
                CategoriaModel(id: 12, nomeRaw: "", nomeKey: "category.vestuario", nomeSubcategoria: nil, tipo: 2, iconeRaw: 14, red: 1.0000, green: 0.2314, blue: 0.1882, opacity: 1.0),
                CategoriaModel(id: 13, nomeRaw: "", nomeKey: "category.casa", nomeSubcategoria: nil, tipo: 2, iconeRaw: 15, red: 1.0000, green: 0.2314, blue: 0.1882, opacity: 0.8),
                CategoriaModel(id: 14, nomeRaw: "", nomeKey: "category.saude", nomeSubcategoria: nil, tipo: 2, iconeRaw: 16, red: 1.0000, green: 0.1765, blue: 0.3333, opacity: 0.8),
                CategoriaModel(id: 15, nomeRaw: "", nomeKey: "category.diarista", nomeSubcategoria: nil, tipo: 2, iconeRaw: 17, red: 0.0000, green: 0.4784, blue: 1.0000, opacity: 1.0),
                CategoriaModel(id: 16, nomeRaw: "", nomeKey: "category.atividade_fisica", nomeSubcategoria: nil, tipo: 2, iconeRaw: 18, red: 0.0000, green: 0.4784, blue: 1.0000, opacity: 0.8),
                CategoriaModel(id: 17, nomeRaw: "", nomeKey: "category.transporte", nomeSubcategoria: nil, tipo: 2, iconeRaw: 19, red: 0.0000, green: 0.4784, blue: 1.0000, opacity: 0.6),
                CategoriaModel(id: 18, nomeRaw: "", nomeKey: "category.refeicao", nomeSubcategoria: nil, tipo: 2, iconeRaw: 20, red: 0.0000, green: 0.8000, blue: 1.0000, opacity: 0.6),
                CategoriaModel(id: 19, nomeRaw: "", nomeKey: "category.imposto_tarifa", nomeSubcategoria: nil, tipo: 2, iconeRaw: 21, red: 0.3451, green: 0.3373, blue: 0.8392, opacity: 1.0),
                CategoriaModel(id: 20, nomeRaw: "", nomeKey: "category.presente", nomeSubcategoria: nil, tipo: 2, iconeRaw: 22, red: 0.0000, green: 0.7373, blue: 0.8314, opacity: 0.6),
                CategoriaModel(id: 21, nomeRaw: "", nomeKey: "category.eletronico", nomeSubcategoria: nil, tipo: 2, iconeRaw: 23, red: 0.3451, green: 0.3373, blue: 0.8392, opacity: 0.6),
                CategoriaModel(id: 22, nomeRaw: "", nomeKey: "category.eletrodomestico", nomeSubcategoria: nil, tipo: 2, iconeRaw: 24, red: 1.0000, green: 0.1765, blue: 0.3333, opacity: 0.4),
                CategoriaModel(id: 23, nomeRaw: "", nomeKey: "category.streaming_tv", nomeSubcategoria: nil, tipo: 2, iconeRaw: 25, red: 0.6863, green: 0.3216, blue: 0.8706, opacity: 1.0),
                CategoriaModel(id: 24, nomeRaw: "", nomeKey: "category.doacao", nomeSubcategoria: nil, tipo: 2, iconeRaw: 26, red: 0.6863, green: 0.3216, blue: 0.8706, opacity: 0.8),
                CategoriaModel(id: 25, nomeRaw: "", nomeKey: "category.estetica", nomeSubcategoria: nil, tipo: 2, iconeRaw: 27, red: 0.6863, green: 0.3216, blue: 0.8706, opacity: 0.6),
                CategoriaModel(id: 26, nomeRaw: "", nomeKey: "category.educacao", nomeSubcategoria: nil, tipo: 2, iconeRaw: 28, red: 0.6863, green: 0.3216, blue: 0.8706, opacity: 0.5),
                CategoriaModel(id: 27, nomeRaw: "", nomeKey: "category.agua_esgoto", nomeSubcategoria: nil, tipo: 2, iconeRaw: 29, red: 0.5569, green: 0.5569, blue: 0.5765, opacity: 1.0),
                CategoriaModel(id: 28, nomeRaw: "", nomeKey: "category.pets", nomeSubcategoria: nil, tipo: 2, iconeRaw: 30, red: 0.5569, green: 0.5569, blue: 0.5765, opacity: 0.6),
                CategoriaModel(id: 29, nomeRaw: "", nomeKey: "category.cuidados_pessoais", nomeSubcategoria: nil, tipo: 2, iconeRaw: 31, red: 0.0000, green: 0.7843, blue: 0.6667, opacity: 1.0)
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
