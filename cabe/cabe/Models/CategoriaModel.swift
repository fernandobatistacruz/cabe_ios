//
//  CategoriaModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import GRDB
import SwiftUI
import UIKit

enum DefaultColorPalette {
    
    static let palette: [(Double, Double, Double, Double)] = [
        (0, 1, 0, 1),
        (0, 1, 0, 0.7),
        (0, 0.5, 0.5, 1),
        (0, 1, 1, 1),
        (1, 1, 0, 1),
        (1, 1, 0, 0.8),
        (1, 1, 0, 0.6),
        (1, 0.5, 0, 1),
        (1, 0.5, 0, 0.8),
        (1, 0.5, 0, 0.5),
        (1, 0, 0.5, 1),
        (1, 0, 0, 1),
        (1, 0, 0, 0.8),
        (1, 0, 0.5, 0.8),
        (0, 0, 1, 1),
        (0, 0, 1, 0.8),
        (0, 0, 1, 0.6),
        (0, 1, 1, 0.6),
        (0.29, 0, 0.51, 1),
        (0, 0.5, 0.5, 0.6),
        (0.29, 0, 0.51, 0.6),
        (1, 0, 0.5, 0.4),
        (0.5, 0, 0.5, 1),
        (0.5, 0, 0.5, 0.8),
        (0.5, 0, 0.5, 0.6),
        (0.5, 0, 0.5, 0.5),
        (0.5, 0.5, 0.5, 1),
        (0.5, 0.5, 0.5, 0.6),
        (0.6, 1, 0.8, 1),
        (0.6, 0.4, 0.2, 1)
    ]
    
    static func rgba(for index: Int) -> (Double, Double, Double, Double) {
        palette.indices.contains(index)
        ? palette[index]
        : (0.5, 0.5, 0.5, 1)
    }
}

struct CategoriaModel: Identifiable, Codable, FetchableRecord, PersistableRecord {
    
    static let databaseTableName = "categoria"
    
    var id: Int64?
    var nomeRaw: String
    var nomeKey: String?
    var nomeSubcategoria: String?
    var tipo: Int
    var iconeRaw: Int
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    var pai: Int64?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nomeRaw = "nome"
        case nomeKey
        case nomeSubcategoria
        case tipo
        case iconeRaw = "icone"
        case red
        case green
        case blue
        case opacity
        case pai
    }
    
    enum Columns {
        static let id = Column("id")
        static let nomeRaw = Column("nome")
        static let nomeKey = Column("nomeKey")
        static let nomeSubcategoria = Column("nomeSubcategoria")
        static let tipo = Column("tipo")
        static let iconeRaw = Column("icone")
        static let red = Column("red")
        static let green = Column("green")
        static let blue = Column("blue")
        static let opacity = Column("opacity")
        static let pai = Column("pai")
    }
}

extension CategoriaModel {
    
    static func defaultCategoria(
        id: Int64,
        nomeKey: String,
        tipo: Int,
        iconeRaw: Int,
        corIndex: Int
    ) -> CategoriaModel {
        
        let rgba = DefaultColorPalette.rgba(for: corIndex)
        
        return CategoriaModel(
            id: id,
            nomeRaw: "",
            nomeKey: nomeKey,
            nomeSubcategoria: nil,
            tipo: tipo,
            iconeRaw: iconeRaw,
            red: rgba.0,
            green: rgba.1,
            blue: rgba.2,
            opacity: rgba.3,
            pai: nil
        )
    }
}

extension CategoriaModel {
  
    var cor: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    var icone: IconeModel {
        IconeModel.icones[safe: iconeRaw] ?? IconeModel.default
    }
    
    var nome: String {
        if let nomeKey, nomeRaw.isEmpty {
            return NSLocalizedString(nomeKey, comment: "")
        }
        return nomeRaw
    }
    
    var isSub: Bool {
        pai != nil
    }
}

extension Color {
    func components() -> (red: Double, green: Double, blue: Double, opacity: Double) {
        let uiColor = UIColor(self)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return (Double(r), Double(g), Double(b), Double(a))
    }
}

struct IconeModel {
    let id: Int
    let systemName: String

    static let icones: [IconeModel] = [
        IconeModel(id: 0, systemName: "creditcard.fill"),
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
        IconeModel(id: 24, systemName: "refrigerator.fill"),
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
        IconeModel(id: 35, systemName: "guitars.fill"),
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
        IconeModel(id: 55, systemName: "film.fill"),
        IconeModel(id: 56, systemName: "hifispeaker.fill"),
        IconeModel(id: 57, systemName: "map.fill"),
        IconeModel(id: 58, systemName: "mic.fill"),
        IconeModel(id: 59, systemName: "moon.fill"),
        IconeModel(id: 60, systemName: "music.note"),
        IconeModel(id: 61, systemName: "paintbrush.fill"),
        IconeModel(id: 62, systemName: "pianokeys"),
        IconeModel(id: 63, systemName: "photo.fill"),
        IconeModel(id: 64, systemName: "magazine.fill"),
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
