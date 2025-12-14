//
//  CartaoModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/12/25.
//

import Foundation

struct CartaoModel {
    let uuid: String
    let nome: String
    let vencimento: Int
    let fechamento: Int
    let operadora: Int
    let limite: Double
    let arquivado: Bool
    let contaUuid: String    
}
