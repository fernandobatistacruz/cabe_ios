import GRDB
import Foundation

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
        
        //TODO: Revisar necessidade desta tabela e remover
        migrator.registerMigration("dropFavoritosTable") { db in
            try db.execute(sql: "DROP TABLE IF EXISTS favoritos")
        }
        
        migrator.registerMigration("addNomeKeyToCategoria") { db in
            try db.alter(table: "categoria") { t in
                t.add(column: "nomeKey", .text)
            }
        }
        
        migrator.registerMigration("seedCategoriasPadrao") { db in
            let count = try CategoriaModel.fetchCount(db)
            guard count == 0 else { return }

            let categoriasPadrao: [CategoriaModel] = [
                // Receitas
                CategoriaModel(id: 0, nomeRaw: "", nomeKey: "category.estorno", tipo: 1, iconeRaw: 5, corRaw: 0, pai: nil),
                CategoriaModel(id: 1, nomeRaw: "", nomeKey: "category.salario", tipo: 1, iconeRaw: 5, corRaw: 0, pai: nil),
                CategoriaModel(id: 2, nomeRaw: "", nomeKey: "category.premio", tipo: 1, iconeRaw: 5, corRaw: 0, pai: nil),
                CategoriaModel(id: 3, nomeRaw: "", nomeKey: "category.investimento", tipo: 1, iconeRaw: 2, corRaw: 0, pai: nil),
                CategoriaModel(id: 4, nomeRaw: "", nomeKey: "category.aluguel", tipo: 1, iconeRaw: 3, corRaw: 0, pai: nil),
                CategoriaModel(id: 5, nomeRaw: "", nomeKey: "category.participacao_resultados", tipo: 1, iconeRaw: 5, corRaw: 0, pai: nil),
                CategoriaModel(id: 6, nomeRaw: "", nomeKey: "category.decimo", tipo: 1, iconeRaw: 5, corRaw: 0, pai: nil),

                // Despesas
                CategoriaModel(id: 1, nomeRaw: "", nomeKey: "category.combustivel", tipo: 2, iconeRaw: 4, corRaw: 1, pai: nil),
                CategoriaModel(id: 2, nomeRaw: "", nomeKey: "category.financiamento", tipo: 2, iconeRaw: 5, corRaw: 2, pai: nil),
                CategoriaModel(id: 3, nomeRaw: "", nomeKey: "category.energia_eletrica", tipo: 2, iconeRaw: 6, corRaw: 3, pai: nil),
                CategoriaModel(id: 4, nomeRaw: "", nomeKey: "category.internet", tipo: 2, iconeRaw: 7, corRaw: 4, pai: nil),
                CategoriaModel(id: 5, nomeRaw: "", nomeKey: "category.seguro", tipo: 2, iconeRaw: 8, corRaw: 5, pai: nil),
                CategoriaModel(id: 6, nomeRaw: "", nomeKey: "category.veiculo", tipo: 2, iconeRaw: 9, corRaw: 6, pai: nil),
                CategoriaModel(id: 7, nomeRaw: "", nomeKey: "category.condominio", tipo: 2, iconeRaw: 3, corRaw: 7, pai: nil),
                CategoriaModel(id: 8, nomeRaw: "", nomeKey: "category.alimentacao", tipo: 2, iconeRaw: 10, corRaw: 8, pai: nil),
                CategoriaModel(id: 9, nomeRaw: "", nomeKey: "category.telefonia", tipo: 2, iconeRaw: 11, corRaw: 9, pai: nil),
                CategoriaModel(id: 10, nomeRaw: "", nomeKey: "category.lazer_hobby", tipo: 2, iconeRaw: 12, corRaw: 0, pai: nil),
                CategoriaModel(id: 11, nomeRaw: "", nomeKey: "category.barbearia_salao", tipo: 2, iconeRaw: 13, corRaw: 10, pai: nil),
                CategoriaModel(id: 12, nomeRaw: "", nomeKey: "category.vestuario", tipo: 2, iconeRaw: 14, corRaw: 11, pai: nil),
                CategoriaModel(id: 13, nomeRaw: "", nomeKey: "category.casa", tipo: 2, iconeRaw: 15, corRaw: 12, pai: nil),
                CategoriaModel(id: 14, nomeRaw: "", nomeKey: "category.saude", tipo: 2, iconeRaw: 16, corRaw: 13, pai: nil),
                CategoriaModel(id: 15, nomeRaw: "", nomeKey: "category.diarista", tipo: 2, iconeRaw: 17, corRaw: 14, pai: nil),
                CategoriaModel(id: 16, nomeRaw: "", nomeKey: "category.atividade_fisica", tipo: 2, iconeRaw: 18, corRaw: 15, pai: nil),
                CategoriaModel(id: 17, nomeRaw: "", nomeKey: "category.transporte", tipo: 2, iconeRaw: 19, corRaw: 16, pai: nil),
                CategoriaModel(id: 18, nomeRaw: "", nomeKey: "category.refeicao", tipo: 2, iconeRaw: 20, corRaw: 17, pai: nil),
                CategoriaModel(id: 19, nomeRaw: "", nomeKey: "category.imposto_tarifa", tipo: 2, iconeRaw: 21, corRaw: 18, pai: nil),
                CategoriaModel(id: 20, nomeRaw: "", nomeKey: "category.presente", tipo: 2, iconeRaw: 22, corRaw: 19, pai: nil),
                CategoriaModel(id: 21, nomeRaw: "", nomeKey: "category.eletronico", tipo: 2, iconeRaw: 23, corRaw: 20, pai: nil),
                CategoriaModel(id: 22, nomeRaw: "", nomeKey: "category.eletrodomestico", tipo: 2, iconeRaw: 24, corRaw: 21, pai: nil),
                CategoriaModel(id: 23, nomeRaw: "", nomeKey: "category.streaming_tv", tipo: 2, iconeRaw: 25, corRaw: 22, pai: nil),
                CategoriaModel(id: 24, nomeRaw: "", nomeKey: "category.doacao", tipo: 2, iconeRaw: 26, corRaw: 23, pai: nil),
                CategoriaModel(id: 25, nomeRaw: "", nomeKey: "category.estetica", tipo: 2, iconeRaw: 27, corRaw: 24, pai: nil),
                CategoriaModel(id: 26, nomeRaw: "", nomeKey: "category.educacao", tipo: 2, iconeRaw: 28, corRaw: 25, pai: nil),
                CategoriaModel(id: 27, nomeRaw: "", nomeKey: "category.agua_esgoto", tipo: 2, iconeRaw: 29, corRaw: 26, pai: nil),
                CategoriaModel(id: 28, nomeRaw: "", nomeKey: "category.pets", tipo: 2, iconeRaw: 30, corRaw: 27, pai: nil),
                CategoriaModel(id: 29, nomeRaw: "", nomeKey: "category.cuidados_pessoais", tipo: 2, iconeRaw: 31, corRaw: 28, pai: nil)
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
