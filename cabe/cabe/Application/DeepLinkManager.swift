//
//  DeepLinkManager.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 09/01/26.
//

import Foundation
internal import Combine
import SwiftUI

enum DeepLink: Hashable {
    case notificacoes
}

final class DeepLinkManager: ObservableObject {
    @Published var path = NavigationPath()
}
