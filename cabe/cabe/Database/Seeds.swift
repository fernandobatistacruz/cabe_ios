//
//  Seeds.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 19/12/25.
//

import GRDB

struct Seeds {

    static func seedCategorias(db: Database) throws {
        try db.execute(sql: """
        INSERT INTO categoria (nome) VALUES
        ('Alimentação'),
        ('Transporte'),
        ('Lazer'),
        ('Moradia'),
        ('Saúde')
        """)
    }
   
}

