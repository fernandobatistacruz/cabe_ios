//
//  EscopoEdicaoRecorrencia.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 17/01/26.
//


//
//  EscopoEdicaoRecorrencia.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 17/01/26.
//

enum EscopoEdicaoRecorrencia: CaseIterable, Identifiable {

    case somenteEste
    case esteEProximos
    case todos

    var id: Self { self }

    var titulo: String {
        switch self {
        case .somenteEste:
            return "Somente este"
        case .esteEProximos:
            return "Este e próximos"
        case .todos:
            return "Todos"
        }
    }
}
