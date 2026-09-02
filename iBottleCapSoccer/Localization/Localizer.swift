import Foundation
import Combine

enum AppLanguage: String {
    case pt
    case en

    var displayCode: String { self == .pt ? "PT" : "EN" }
}

final class Localizer: ObservableObject {
    static let shared = Localizer()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "fdc_lang") }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "fdc_lang"),
           let lang = AppLanguage(rawValue: saved) {
            language = lang
        } else {
            let preferred = Locale.preferredLanguages.first ?? "pt"
            language = preferred.hasPrefix("en") ? .en : .pt
        }
    }

    func toggle() {
        language = language == .pt ? .en : .pt
    }

    func t(_ key: LocKey) -> String {
        strings[language]?[key] ?? key.rawValue
    }

    private let strings: [AppLanguage: [LocKey: String]] = [
        .pt: [
            .appTitle: "Futebol de Caricas",
            .navRules: "Regras",
            .navNewGame: "Novo Jogo",
            .teamHome: "Equipa Casa",
            .teamAway: "Equipa Fora",
            .half1: "1ª Parte",
            .half2: "2ª Parte",
            .halftime: "Intervalo",
            .fulltime: "Fim de Jogo",
            .turnHome: "Vez da Equipa Casa",
            .turnAway: "Vez da Equipa Fora",
            .actionsLeft: "Ações restantes:",
            .goalText: "GOLO!",
            .hintText: "Arrasta uma carica da tua equipa e solta para chutar. Chega ao meio-campo adversário para poderes rematar à baliza.",
            .restart: "Jogar Novamente",
            .splashSkip: "Saltar",
            .splashCredit: "Developed by David Arsénio Martins",
            .rulesTitle: "Regras do Futebol de Caricas",
            .rulesObjectiveTitle: "Objetivo",
            .rulesObjectiveBody: "Marcar mais golos que a equipa adversária, chutando as caricas com precisão para empurrar a bola até à baliza contrária.",
            .rulesDurationTitle: "Duração",
            .rulesDurationBody: "2 partes de 15 minutos, sem interrupções.",
            .rulesHowTitle: "Como jogar",
            .rulesHowBody: "Arrasta uma carica da tua equipa e solta para a chutar na direção e força desejadas. Cada jogador tem 1, 2 ou 3 ações por vez. Não é permitido tocar numa carica sem a deslocar de forma percetível.",
            .rulesShootTitle: "Remate à baliza",
            .rulesShootBody: "Só podes rematar quando a tua carica está no meio-campo adversário — é obrigatório anunciar o remate.",
            .rulesSpecialTitle: "Regras especiais",
            .rulesSpecialBody: "Não existe fora de jogo nem fora de campo. Existe lei da mão: se a bola cair dentro de uma carica tua vinda do adversário, é falta.",
            .rulesPlaysTitle: "Jogadas especiais",
            .rulesPlaysBody: "Penáltis, livres diretos, cantos, laterais e pontapé de baliza — tal como no futebol tradicional.",
            .close: "Fechar",
            .menuSubtitle: "O clássico jogo de caricas, direto do recreio",
            .menuPlay: "Jogar",
            .menuRules: "Regras",
            .menuBackToMenu: "Menu",
        ],
        .en: [
            .appTitle: "Bottle Cap Soccer",
            .navRules: "Rules",
            .navNewGame: "New Game",
            .teamHome: "Home Team",
            .teamAway: "Away Team",
            .half1: "1st Half",
            .half2: "2nd Half",
            .halftime: "Half-Time",
            .fulltime: "Full Time",
            .turnHome: "Home Team's Turn",
            .turnAway: "Away Team's Turn",
            .actionsLeft: "Actions left:",
            .goalText: "GOAL!",
            .hintText: "Drag a cap from your team and release to shoot. Reach the opponent's half to be able to shoot at goal.",
            .restart: "Play Again",
            .splashSkip: "Skip",
            .splashCredit: "Developed by David Arsénio Martins",
            .rulesTitle: "Bottle Cap Soccer Rules",
            .rulesObjectiveTitle: "Objective",
            .rulesObjectiveBody: "Score more goals than the opposing team by flicking your caps to push the ball into the opponent's goal.",
            .rulesDurationTitle: "Duration",
            .rulesDurationBody: "2 halves of 15 minutes each, played without stoppages.",
            .rulesHowTitle: "How to play",
            .rulesHowBody: "Drag a cap from your team and release to flick it in the desired direction and strength. Each player gets 1, 2 or 3 actions per turn. A cap can't be touched without moving it noticeably.",
            .rulesShootTitle: "Shooting on goal",
            .rulesShootBody: "You can only shoot when your cap is in the opponent's half — the shot must be announced beforehand.",
            .rulesSpecialTitle: "Special rules",
            .rulesSpecialBody: "No offside rule and no out of bounds. Handball rule applies: if the ball lands inside one of your caps off an opponent's play, it's a foul.",
            .rulesPlaysTitle: "Special plays",
            .rulesPlaysBody: "Penalties, direct free-kicks, corners, throw-ins and goal-kicks — just like traditional football.",
            .close: "Close",
            .menuSubtitle: "The classic bottle cap game, straight from the schoolyard",
            .menuPlay: "Play",
            .menuRules: "Rules",
            .menuBackToMenu: "Menu",
        ],
    ]
}

enum LocKey: String {
    case appTitle, navRules, navNewGame, teamHome, teamAway
    case half1, half2, halftime, fulltime
    case turnHome, turnAway, actionsLeft, goalText, hintText, restart
    case splashSkip, splashCredit
    case rulesTitle
    case rulesObjectiveTitle, rulesObjectiveBody
    case rulesDurationTitle, rulesDurationBody
    case rulesHowTitle, rulesHowBody
    case rulesShootTitle, rulesShootBody
    case rulesSpecialTitle, rulesSpecialBody
    case rulesPlaysTitle, rulesPlaysBody
    case close
    case menuSubtitle, menuPlay, menuRules, menuBackToMenu
}
