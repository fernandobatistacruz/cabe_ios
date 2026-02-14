//
//  OrdemData.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/02/26.
//

import Foundation


enum OrdemData: CaseIterable {
    case crescente
    case decrescente

    var titulo: LocalizedStringResource {
        self == .crescente ? "Crescente" : "Decrescente"
    }

    var icon: String {
        self == .crescente ? "arrow.up" : "arrow.down"
    }
}
