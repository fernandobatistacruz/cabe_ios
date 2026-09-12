//
//  BancoLogo.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 12/09/26.
//

import SwiftUI

enum BancoLogo: Int, CaseIterable, Identifiable {
    case outro = 0
    case bb = 1
    case itau = 2
    case bradesco = 3
    case nubank = 4
    case santander = 5
    case inter = 6
    case btg = 7
    case caixa = 8
   

    var id: Int { rawValue }
   
    var assetName: String {
        switch self {
        case .outro: "outro"
        case .bb: "bb"
        case .itau: "itau"
        case .bradesco: "bradesco"
        case .nubank: "nubank"
        case .santander: "santander"
        case .inter: "inter"
        case .btg: "btg"
        case .caixa: "caixa"
        }
    }
}

struct LogoBancoView: View {
    let codigo: Int
    
    var body: some View {
        if let banco = BancoLogo(rawValue: codigo) {
            Image(banco.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: "building.columns.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.blue)
                .frame(width: 24, height: 24)
        }
    }
}
