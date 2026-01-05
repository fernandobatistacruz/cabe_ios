import GRDB

extension AppDatabase {

    static func makeMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.eraseDatabaseOnSchemaChange = false
      
        migrator.registerMigration("baseline_v23") { _ in }
        
        migrator.registerMigration("create_schema_v23") { db in
           
            let exists = try db.tableExists("lancamento")
            guard !exists else { return }

            try db.create(table: "conta") { t in
                t.column("uuid", .text).primaryKey()
                t.column("nome", .text).notNull()
                t.column("saldo", .double).notNull()
            }

            try db.create(table: "cartao") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("uuid", .text).notNull()
                t.column("nome", .text).notNull()
                t.column("limite", .double)
                t.column("arquivado", .boolean).notNull().defaults(to: false)
                t.column("conta_uuid", .text)
                    .notNull()
                    .references("conta", onDelete: .cascade)
            }

            try db.create(table: "lancamento") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("pago", .boolean).notNull().defaults(to: false)
                t.column("dividido", .boolean).notNull().defaults(to: false)
                t.column("transferencia", .boolean).notNull().defaults(to: false)
                t.column("notificado", .boolean).notNull().defaults(to: false)
                t.column("anotacao", .text).defaults(to: "")
                t.column("data_criacao", .text)
                    .defaults(to: "1990-01-01")
                t.column("cartao_uuid", .text)
                t.column("conta_uuid", .text).notNull()
            }

            try db.create(table: "categoria") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("nome", .text).notNull()
                t.column("pai", .integer)
                t.column("nome_subcategoria", .text)
            }

            try db.create(table: "favoritos") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("nome", .text)
            }

            // Seeds
            //try Seeds.seedCategorias(db: db)
           

            //AppAjustes().setCarteira(["conta", "0", "Conta Inicial"])
        }
        
        migrator.registerMigration("addCurrencyCodeToConta") { db in
            try db.execute(sql: """
                        ALTER TABLE conta
                        ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'BRL';
                    """)
        }
        
        migrator.registerMigration("addNotificacaoLida") { db in
            try db.execute(sql: """
                ALTER TABLE lancamento
                ADD COLUMN notificacao_lida BOOLEAN NOT NULL DEFAULT 0;
            """)
        }

        return migrator
    }
}





