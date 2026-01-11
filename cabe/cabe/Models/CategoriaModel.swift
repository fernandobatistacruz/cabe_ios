//
//  CategoriaModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import GRDB
import SwiftUI

struct CategoriaModel: Identifiable, Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "categoria"
    
    var id: Int64?
    var nome: String
    var nomeSubcategoria: String?
    var tipo: Int
    var icone: Int
    var cor: Int
    var pai: Int64?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nome
        case nomeSubcategoria
        case tipo
        case icone
        case cor
        case pai
    }
    
    enum Columns {
        static let id = Column("id")
        static let nome = Column("nome")
        static let nomeSubcategoria = Column("nomeSubcategoria")
        static let tipo = Column("tipo")
        static let icone = Column("icone")
        static let cor = Column("cor")
        static let pai = Column("pai")
    }
    
    func getCor() -> CorModel {
        CorModel.cores[safe: cor] ?? CorModel.default
    }

    func getIcone() -> IconeModel {
        IconeModel.icones[safe: icone] ?? IconeModel.default
    }
}

struct CorModel {
    let id: Int
    let cor: Color

    static let cores: [CorModel] = [
        CorModel(id: 0, cor: .green),
        CorModel(id: 1, cor: .green),
        CorModel(id: 2, cor: .teal),
        CorModel(id: 3, cor: .cyan),
        CorModel(id: 4, cor: .yellow),
        CorModel(id: 5, cor: .yellow.opacity(0.8)),
        CorModel(id: 6, cor: .yellow.opacity(0.6)),
        CorModel(id: 7, cor: .orange),
        CorModel(id: 8, cor: .orange.opacity(0.8)),
        CorModel(id: 9, cor: .orange),
        CorModel(id: 10, cor: .pink),
        CorModel(id: 11, cor: .red),
        CorModel(id: 12, cor: .red.opacity(0.8)),
        CorModel(id: 13, cor: .pink.opacity(0.8)),
        CorModel(id: 14, cor: .blue),
        CorModel(id: 15, cor: .blue),
        CorModel(id: 16, cor: .blue.opacity(0.6)),
        CorModel(id: 17, cor: .cyan.opacity(0.6)),
        CorModel(id: 18, cor: .indigo),
        CorModel(id: 19, cor: .teal),
        CorModel(id: 20, cor: .indigo),
        CorModel(id: 21, cor: .pink.opacity(0.4)),
        CorModel(id: 22, cor: .purple),
        CorModel(id: 23, cor: .purple),
        CorModel(id: 24, cor: .purple.opacity(0.7)),
        CorModel(id: 25, cor: .purple.opacity(0.8)),
        CorModel(id: 26, cor: .gray),
        CorModel(id: 27, cor: .gray.opacity(0.7)),
        CorModel(id: 28, cor: .blue.opacity(0.4)),
        CorModel(id: 29, cor: .brown)
    ]

    static let `default` = CorModel(id: -1, cor: .gray)
}

struct IconeModel {
    let id: Int
    let systemName: String

    static let icones: [IconeModel] = [
        IconeModel(id: 0, systemName: "creditcard"),
        IconeModel(id: 1, systemName: "sun.max.fill"),
        IconeModel(id: 2, systemName: "chart.bar.fill"),
        IconeModel(id: 3, systemName: "building.2.fill"),
        IconeModel(id: 4, systemName: "fuelpump.fill"),
        IconeModel(id: 5, systemName: "banknote.fill"),
        IconeModel(id: 6, systemName: "bolt.fill"),
        IconeModel(id: 7, systemName: "wifi"),
        IconeModel(id: 8, systemName: "lock.fill"),
        IconeModel(id: 9, systemName: "car.fill"),
        IconeModel(id: 10, systemName: "cart.fill"),
        IconeModel(id: 11, systemName: "phone.fill"),
        IconeModel(id: 12, systemName: "face.smiling.fill"),
        IconeModel(id: 13, systemName: "person.2.fill"),
        IconeModel(id: 14, systemName: "storefront.fill"),
        IconeModel(id: 15, systemName: "house.fill"),
        IconeModel(id: 16, systemName: "heart.fill"),
        IconeModel(id: 17, systemName: "sparkles"),
        IconeModel(id: 18, systemName: "dumbbell.fill"),
        IconeModel(id: 19, systemName: "bus.fill"),
        IconeModel(id: 20, systemName: "fork.knife"),
        IconeModel(id: 21, systemName: "barcode"),
        IconeModel(id: 22, systemName: "gift.fill"),
        IconeModel(id: 23, systemName: "laptopcomputer"),
        IconeModel(id: 24, systemName: "refrigerator"),
        IconeModel(id: 25, systemName: "tv.music.note.fill"),
        IconeModel(id: 26, systemName: "lifepreserver.fill"),
        IconeModel(id: 27, systemName: "eye.fill"),
        IconeModel(id: 28, systemName: "book.fill"),
        IconeModel(id: 29, systemName: "drop.fill"),
        IconeModel(id: 30, systemName: "pawprint.fill"),
        IconeModel(id: 31, systemName: "person.fill"),
        IconeModel(id: 32, systemName: "square.grid.2x2.fill"),
        IconeModel(id: 33, systemName: "gamecontroller.fill"),
        IconeModel(id: 34, systemName: "hammer.fill"),
        IconeModel(id: 35, systemName: "guitars"),
        IconeModel(id: 36, systemName: "bag.fill"),
        IconeModel(id: 37, systemName: "cloud.fill"),
        IconeModel(id: 38, systemName: "airplane"),
        IconeModel(id: 39, systemName: "flask.fill"),
        IconeModel(id: 40, systemName: "tortoise.fill"),
        IconeModel(id: 41, systemName: "ticket.fill"),
        IconeModel(id: 42, systemName: "tree.fill"),
        IconeModel(id: 43, systemName: "umbrella.fill"),
        IconeModel(id: 44, systemName: "video.fill"),
        IconeModel(id: 45, systemName: "wrench.fill"),
        IconeModel(id: 46, systemName: "tv.fill"),
        IconeModel(id: 47, systemName: "speaker.2.fill"),
        IconeModel(id: 48, systemName: "ant.fill"),
        IconeModel(id: 49, systemName: "archivebox.fill"),
        IconeModel(id: 50, systemName: "bandage.fill"),
        IconeModel(id: 51, systemName: "bed.double.fill"),
        IconeModel(id: 52, systemName: "briefcase.fill"),
        IconeModel(id: 53, systemName: "camera.fill"),
        IconeModel(id: 54, systemName: "chart.pie.fill"),
        IconeModel(id: 55, systemName: "film"),
        IconeModel(id: 56, systemName: "hifispeaker.fill"),
        IconeModel(id: 57, systemName: "map.fill"),
        IconeModel(id: 58, systemName: "mic.fill"),
        IconeModel(id: 59, systemName: "moon.fill"),
        IconeModel(id: 60, systemName: "music.note"),
        IconeModel(id: 61, systemName: "paintbrush.fill"),
        IconeModel(id: 62, systemName: "pianokeys"),
        IconeModel(id: 63, systemName: "photo.fill"),
        IconeModel(id: 64, systemName: "rocket.fill"),
        IconeModel(id: 65, systemName: "sportscourt.fill"),
        IconeModel(id: 66, systemName: "suit.spade.fill"),
        IconeModel(id: 67, systemName: "headphones"),
        IconeModel(id: 68, systemName: "iphone"),
        IconeModel(id: 69, systemName: "scissors"),
        IconeModel(id: 70, systemName: "tag.fill"),
        IconeModel(id: 71, systemName: "ticket.fill")
    ]

    static let `default` = IconeModel(id: -1, systemName: "questionmark.circle")
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension CategoriaModel {
    static var outros: CategoriaModel {
        CategoriaModel(
            id: nil,                     // não vem do banco
            nome: "Outros",
            nomeSubcategoria: nil,
            tipo: Tipo.despesa.rawValue, // importante
            icone: IconeModel.default.id,
            cor: CorModel.default.id,
            pai: nil
        )
    }
}

extension CategoriaModel {

    /// Retorna a cor correta considerando herança do pai (se existir)
    func corEfetiva(todas: [CategoriaModel]) -> CorModel {
        if let paiId = pai,
           let categoriaPai = todas.first(where: { $0.id == paiId  && $0.tipo == tipo}) {
            return categoriaPai.getCor()
        }
        return getCor()
    }

    /// Retorna o ícone correto considerando herança do pai (se existir)
    func iconeEfetivo(todas: [CategoriaModel]) -> IconeModel {
        if let paiId = pai,
           let categoriaPai = todas.first(where: { $0.id == paiId && $0.tipo == tipo }) {
            return categoriaPai.getIcone()
        }
        return getIcone()
    }
}




