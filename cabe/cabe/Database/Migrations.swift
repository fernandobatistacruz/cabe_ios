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
                t.column("saldo", .double).notNull().defaults(to: 0)
                t.column("currency_code", .text).notNull()
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
        
        /*
        migrator.registerMigration("addCurrencyCodeToConta") { db in
            try db.alter(table: "conta") { t in
                t.add(column: "currency_code", .text)
                    .notNull()
                    .defaults(to: defaultCurrencyCode)
            }
        }
         */
         
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
            guard count == 0 else { return } // só em instalação nova

            let categoriasPadrao: [CategoriaModel] = [
                // Receitas
                CategoriaModel(id: 0, nomeRaw: "", nomeKey: "category.estorno", tipo: 1, icone: 0, cor: 0, pai: nil),
                CategoriaModel(id: 1, nomeRaw: "", nomeKey: "category.salario", tipo: 1, icone: 0, cor: 0, pai: nil),
                CategoriaModel(id: 2, nomeRaw: "", nomeKey: "category.premio", tipo: 1, icone: 0, cor: 0, pai: nil),
                CategoriaModel(id: 3, nomeRaw: "", nomeKey: "category.investimento", tipo: 1, icone: 2, cor: 0, pai: nil),
                CategoriaModel(id: 4, nomeRaw: "", nomeKey: "category.aluguel", tipo: 1, icone: 3, cor: 0, pai: nil),
                CategoriaModel(id: 5, nomeRaw: "", nomeKey: "category.participacao_resultados", tipo: 1, icone: 0, cor: 0, pai: nil),
                CategoriaModel(id: 6, nomeRaw: "", nomeKey: "category.decimo", tipo: 1, icone: 0, cor: 0, pai: nil),

                // Despesas
                CategoriaModel(id: 1, nomeRaw: "", nomeKey: "category.combustivel", tipo: 2, icone: 4, cor: 1, pai: nil),
                CategoriaModel(id: 2, nomeRaw: "", nomeKey: "category.financiamento", tipo: 2, icone: 5, cor: 2, pai: nil),
                CategoriaModel(id: 3, nomeRaw: "", nomeKey: "category.energia_eletrica", tipo: 2, icone: 6, cor: 3, pai: nil),
                CategoriaModel(id: 4, nomeRaw: "", nomeKey: "category.internet", tipo: 2, icone: 7, cor: 4, pai: nil),
                CategoriaModel(id: 5, nomeRaw: "", nomeKey: "category.seguro", tipo: 2, icone: 8, cor: 5, pai: nil),
                CategoriaModel(id: 6, nomeRaw: "", nomeKey: "category.veiculo", tipo: 2, icone: 9, cor: 6, pai: nil),
                CategoriaModel(id: 7, nomeRaw: "", nomeKey: "category.condominio", tipo: 2, icone: 3, cor: 7, pai: nil),
                CategoriaModel(id: 8, nomeRaw: "", nomeKey: "category.alimentacao", tipo: 2, icone: 10, cor: 8, pai: nil),
                CategoriaModel(id: 9, nomeRaw: "", nomeKey: "category.telefonia", tipo: 2, icone: 11, cor: 9, pai: nil),
                CategoriaModel(id: 10, nomeRaw: "", nomeKey: "category.lazer_hobby", tipo: 2, icone: 12, cor: 0, pai: nil),
                CategoriaModel(id: 11, nomeRaw: "", nomeKey: "category.barbearia_salao", tipo: 2, icone: 13, cor: 10, pai: nil),
                CategoriaModel(id: 12, nomeRaw: "", nomeKey: "category.vestuario", tipo: 2, icone: 14, cor: 11, pai: nil),
                CategoriaModel(id: 13, nomeRaw: "", nomeKey: "category.casa", tipo: 2, icone: 15, cor: 12, pai: nil),
                CategoriaModel(id: 14, nomeRaw: "", nomeKey: "category.saude", tipo: 2, icone: 16, cor: 13, pai: nil),
                CategoriaModel(id: 15, nomeRaw: "", nomeKey: "category.diarista", tipo: 2, icone: 17, cor: 14, pai: nil),
                CategoriaModel(id: 16, nomeRaw: "", nomeKey: "category.atividade_fisica", tipo: 2, icone: 18, cor: 15, pai: nil),
                CategoriaModel(id: 17, nomeRaw: "", nomeKey: "category.transporte", tipo: 2, icone: 19, cor: 16, pai: nil),
                CategoriaModel(id: 18, nomeRaw: "", nomeKey: "category.refeicao", tipo: 2, icone: 20, cor: 17, pai: nil),
                CategoriaModel(id: 19, nomeRaw: "", nomeKey: "category.imposto_tarifa", tipo: 2, icone: 21, cor: 18, pai: nil),
                CategoriaModel(id: 20, nomeRaw: "", nomeKey: "category.presente", tipo: 2, icone: 22, cor: 19, pai: nil),
                CategoriaModel(id: 21, nomeRaw: "", nomeKey: "category.eletronico", tipo: 2, icone: 23, cor: 20, pai: nil),
                CategoriaModel(id: 22, nomeRaw: "", nomeKey: "category.eletrodomestico", tipo: 2, icone: 24, cor: 21, pai: nil),
                CategoriaModel(id: 23, nomeRaw: "", nomeKey: "category.streaming_tv", tipo: 2, icone: 25, cor: 22, pai: nil),
                CategoriaModel(id: 24, nomeRaw: "", nomeKey: "category.doacao", tipo: 2, icone: 26, cor: 23, pai: nil),
                CategoriaModel(id: 25, nomeRaw: "", nomeKey: "category.estetica", tipo: 2, icone: 27, cor: 24, pai: nil),
                CategoriaModel(id: 26, nomeRaw: "", nomeKey: "category.educacao", tipo: 2, icone: 28, cor: 25, pai: nil),
                CategoriaModel(id: 27, nomeRaw: "", nomeKey: "category.agua_esgoto", tipo: 2, icone: 29, cor: 26, pai: nil),
                CategoriaModel(id: 28, nomeRaw: "", nomeKey: "category.pets", tipo: 2, icone: 30, cor: 27, pai: nil),
                CategoriaModel(id: 29, nomeRaw: "", nomeKey: "category.cuidados_pessoais", tipo: 2, icone: 31, cor: 28, pai: nil)
            ]

            for cat in categoriasPadrao {
                try cat.insert(db)
            }
        }
        
        return migrator
    }
}
