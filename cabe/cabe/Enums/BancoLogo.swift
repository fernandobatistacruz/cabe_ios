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
    case hsbc = 9
    case banamex = 10
    case bancodebogota = 11
    case bancodechile = 12
    case bancoestado = 13
    case bancolombia = 14
    case bancomacro = 15
    case banconacion = 16
    case bankofamerica = 17
    case banorte = 18
    case bbva = 19
    case bci = 20
    case bcp = 21
    case brou = 22
    case chase = 23
    case citibank = 24
    case davivienda = 25
    case galicia = 26
    case interbank = 27
    case pichincha = 28
    case scotiabank = 29
    case usbank = 30
    case wellsfargo = 31

    var id: Int { rawValue }
    
    var nome: LocalizedStringResource {
        switch self {
        case .outro: "Outro"
        case .bb: "Banco do Brasil"
        case .itau: "Itaú"
        case .bradesco: "Bradesco"
        case .nubank: "Nubank"
        case .santander: "Santander"
        case .inter: "Inter"
        case .btg: "BTG Pactual"
        case .caixa: "Caixa"
        case .hsbc: "HSBC"
        case .banamex: "Banamex"
        case .bancodebogota: "Banco de Bogotá"
        case .bancodechile: "Banco de Chile"
        case .bancoestado: "Banco Estado"
        case .bancolombia: "Bancolombia"
        case .bancomacro: "Banco Macro"
        case .banconacion: "BNA"
        case .bankofamerica: "Bank of America"
        case .banorte: "Banorte"
        case .bbva: "BBVA"
        case .bci: "Banco Bci"
        case .bcp: "BCP"
        case .brou: "Banco República"
        case .chase: "Chase"
        case .citibank: "Citibank"
        case .davivienda: "Davivienda"
        case .galicia: "Galicia"
        case .interbank: "Interbank"
        case .pichincha: "Banco Pichincha"
        case .scotiabank: "Scotiabank"
        case .usbank: "U.S. Bank"
        case .wellsfargo: "Wells Fargo"
        }
    }
   
    var imageName: String {
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
        case .hsbc: "hsbc"
        case .banamex: "banamex"
        case .bancodebogota: "bancodebogota"
        case .bancodechile: "bancodechile"
        case .bancoestado: "bancoestado"
        case .bancolombia: "bancolombia"
        case .bancomacro: "bancomacro"
        case .banconacion: "banconacion"
        case .bankofamerica: "bankofamerica"
        case .banorte: "banorte"
        case .bbva: "bbva"
        case .bci: "bci"
        case .bcp: "bcp"
        case .brou: "brou"
        case .chase: "chase"
        case .citibank: "citibank"
        case .davivienda: "davivienda"
        case .galicia: "galicia"
        case .interbank: "interbank"
        case .pichincha: "pichincha"
        case .scotiabank: "scotiabank"
        case .usbank: "usbank"
        case .wellsfargo: "wellsfargo"
        }
    }
}

struct LogoBancoView: View {
    let logo: Int
    
    var body: some View {
        if let banco = BancoLogo(rawValue: logo) {
            Image(banco.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        } else {
            Image(systemName: "building.columns.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.blue)
                .frame(width: 24, height: 24)
        }
    }
}
