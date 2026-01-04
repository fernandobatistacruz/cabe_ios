//
//  Tipo.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import SwiftUI

enum Tipo: Int, CaseIterable {
    case receita = 1
    case despesa = 2

    var descricao: LocalizedStringKey {
        switch self {
        case .receita: return "Receita"
        case .despesa: return "Despesa"       
        }
    }
}

