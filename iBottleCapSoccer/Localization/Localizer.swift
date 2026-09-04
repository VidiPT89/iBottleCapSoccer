import Foundation
import Combine

enum AppLanguage: String {
    case pt
    case en
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
            .fulltime: "Fim de Jogo",
            .turnHome: "Vez da Equipa Casa",
            .turnAway: "Vez da Equipa Fora",
            .goalText: "GOLO!",
            .hintText: "Arrasta uma carica da tua equipa e solta para chutar. Chega ao meio-campo adversário para poderes rematar à baliza.",
            .restart: "Jogar Novamente",
            .splashSkip: "Saltar",
            .rulesTitle: "Regras do Futebol de Caricas",
            .rulesObjectiveTitle: "Objetivo",
            .rulesObjectiveBody: "Marcar mais golos que a equipa adversária, chutando as caricas com precisão para empurrar a bola até à baliza contrária.",
            .rulesDurationTitle: "Duração",
            .rulesDurationBody: "2 partes de 15 minutos, sem interrupções — ou, se escolheres um limite de golos ao iniciar (ex: primeiro a 5), o jogo também pode terminar mais cedo.",
            .rulesHowTitle: "Como jogar",
            .rulesHowBody: "Arrasta uma carica da tua equipa e solta para a chutar na direção e força desejadas. Depois de cada jogada, passa a vez à equipa adversária. Não é permitido tocar numa carica sem a deslocar de forma percetível.",
            .rulesShootTitle: "Remate à baliza",
            .rulesShootBody: "Só podes rematar quando a tua carica está no meio-campo adversário — é obrigatório anunciar o remate.",
            .rulesSpecialTitle: "Regras especiais",
            .rulesSpecialBody: "Não existe fora de jogo nem fora de campo (o campo é murado). É falta cada vez que a tua carica choca contra uma carica adversária antes de tocar na bola — 3 faltas seguidas da mesma equipa dão um livre direto (um turno extra) ao adversário. O guarda-redes flicta com mais força e mais agilidade que um jogador de campo.",
            .rulesPlaysTitle: "Jogadas especiais",
            .rulesPlaysBody: "O livre direto por faltas acontece dentro do próprio jogo (ver Regras especiais). Para treinar remates isolados, usa o modo \"Treino de Pénaltis\" no menu principal.",
            .close: "Fechar",
            .menuSubtitle: "O clássico jogo de caricas, direto do recreio",
            .menuPlay: "Jogar",
            .menuContinue: "Continuar",
            .menuRules: "Regras",
            .menuBackToMenu: "Menu",
            .menuStep1: "Arrasta",
            .menuStep2: "Solta",
            .menuStep3: "Marca",
            .modePickerTitle: "Escolhe o modo de jogo",
            .mode1v1: "1 vs 1 (Local)",
            .mode1v1Subtitle: "Dois jogadores no mesmo aparelho",
            .modeBot: "1 vs Bot",
            .modeBotSubtitle: "Joga contra o computador",
            .modeOnline: "Online",
            .modeOnlineSubtitle: "Game Center, por turnos",
            .botDifficultyTitle: "Escolhe a dificuldade",
            .botEasy: "Fácil",
            .botMedium: "Médio",
            .botHard: "Difícil",
            .cancel: "Cancelar",
            .back: "Voltar",
            .onlineFirstTo5: "Primeiro a 5 golos",
            .onlineOpponentTurn: "Vez do adversário",
            .onlineYourTurn: "A tua vez",
            .botThinking: "O bot está a jogar…",
            .foulText: "Falta!",
            .freeKickText: "Livre Direto!",
            .ambientToggle: "Som ambiente",
            .statsTitle: "Estatísticas",
            .statsGoals: "Golos marcados",
            .statsPlayed: "Jogos disputados",
            .statsWon: "Jogos ganhos",
            .customizeTitle: "Personalizar equipas",
            .customizeHome: "Equipa Casa",
            .customizeAway: "Equipa Fora",
            .menuTraining: "Treino de Pénaltis",
            .menuCareer: "Carreira",
            .trainingTitle: "Treino de Pénaltis",
            .trainingScore: "Convertidos",
            .careerTitle: "Carreira",
            .careerLocked: "Vence o desafio anterior para desbloquear",
            .careerWon: "Vencido",
            .careerPlay: "Jogar",
            .careerStage: "Desafio",
            .goalTargetTitle: "Limite de golos",
            .goalTargetNone: "Sem limite",
            .goalTargetScope: "Local/Bot apenas",
        ],
        .en: [
            .appTitle: "Bottle Cap Soccer",
            .navRules: "Rules",
            .navNewGame: "New Game",
            .teamHome: "Home Team",
            .teamAway: "Away Team",
            .half1: "1st Half",
            .half2: "2nd Half",
            .fulltime: "Full Time",
            .turnHome: "Home Team's Turn",
            .turnAway: "Away Team's Turn",
            .goalText: "GOAL!",
            .hintText: "Drag a cap from your team and release to shoot. Reach the opponent's half to be able to shoot at goal.",
            .restart: "Play Again",
            .splashSkip: "Skip",
            .rulesTitle: "Bottle Cap Soccer Rules",
            .rulesObjectiveTitle: "Objective",
            .rulesObjectiveBody: "Score more goals than the opposing team by flicking your caps to push the ball into the opponent's goal.",
            .rulesDurationTitle: "Duration",
            .rulesDurationBody: "2 halves of 15 minutes each, played without stoppages — or, if you pick a goal limit when starting (e.g. first to 5), the match can also end early.",
            .rulesHowTitle: "How to play",
            .rulesHowBody: "Drag a cap from your team and release to flick it in the desired direction and strength. After each move, the turn passes to the other team. A cap can't be touched without moving it noticeably.",
            .rulesShootTitle: "Shooting on goal",
            .rulesShootBody: "You can only shoot when your cap is in the opponent's half — the shot must be announced beforehand.",
            .rulesSpecialTitle: "Special rules",
            .rulesSpecialBody: "No offside and no out of bounds (the pitch is walled). Charging into an opponent's cap before touching the ball is a foul — three in a row by the same team hand the opponent a free kick (an extra turn). The goalkeeper flicks with more power and agility than a field cap.",
            .rulesPlaysTitle: "Special plays",
            .rulesPlaysBody: "The direct free kick from fouls happens within the match itself (see Special rules). For isolated flick practice, use \"Penalty Training\" from the main menu.",
            .close: "Close",
            .menuSubtitle: "The classic bottle cap game, straight from the schoolyard",
            .menuPlay: "Play",
            .menuContinue: "Continue",
            .menuRules: "Rules",
            .menuBackToMenu: "Menu",
            .menuStep1: "Drag",
            .menuStep2: "Release",
            .menuStep3: "Score",
            .modePickerTitle: "Choose a game mode",
            .mode1v1: "1 vs 1 (Local)",
            .mode1v1Subtitle: "Two players, same device",
            .modeBot: "1 vs Bot",
            .modeBotSubtitle: "Play against the computer",
            .modeOnline: "Online",
            .modeOnlineSubtitle: "Game Center, turn-based",
            .botDifficultyTitle: "Choose a difficulty",
            .botEasy: "Easy",
            .botMedium: "Medium",
            .botHard: "Hard",
            .cancel: "Cancel",
            .back: "Back",
            .onlineFirstTo5: "First to 5 goals",
            .onlineOpponentTurn: "Opponent's turn",
            .onlineYourTurn: "Your turn",
            .botThinking: "Bot is playing…",
            .foulText: "Foul!",
            .freeKickText: "Free Kick!",
            .ambientToggle: "Ambient sound",
            .statsTitle: "Stats",
            .statsGoals: "Goals scored",
            .statsPlayed: "Matches played",
            .statsWon: "Matches won",
            .customizeTitle: "Customize teams",
            .customizeHome: "Home Team",
            .customizeAway: "Away Team",
            .menuTraining: "Penalty Training",
            .menuCareer: "Career",
            .trainingTitle: "Penalty Training",
            .trainingScore: "Converted",
            .careerTitle: "Career",
            .careerLocked: "Win the previous challenge to unlock",
            .careerWon: "Won",
            .careerPlay: "Play",
            .careerStage: "Challenge",
            .goalTargetTitle: "Goal limit",
            .goalTargetNone: "No limit",
            .goalTargetScope: "Local/Bot only",
        ],
    ]
}

enum LocKey: String {
    case appTitle, navRules, navNewGame, teamHome, teamAway
    case half1, half2, fulltime
    case turnHome, turnAway, goalText, hintText, restart
    case splashSkip
    case rulesTitle
    case rulesObjectiveTitle, rulesObjectiveBody
    case rulesDurationTitle, rulesDurationBody
    case rulesHowTitle, rulesHowBody
    case rulesShootTitle, rulesShootBody
    case rulesSpecialTitle, rulesSpecialBody
    case rulesPlaysTitle, rulesPlaysBody
    case close
    case menuSubtitle, menuPlay, menuContinue, menuRules, menuBackToMenu
    case menuStep1, menuStep2, menuStep3
    case modePickerTitle, mode1v1, mode1v1Subtitle, modeBot, modeBotSubtitle, modeOnline, modeOnlineSubtitle
    case botDifficultyTitle, botEasy, botMedium, botHard
    case cancel, back
    case onlineFirstTo5, onlineOpponentTurn, onlineYourTurn, botThinking
    case foulText, freeKickText, ambientToggle
    case statsTitle, statsGoals, statsPlayed, statsWon
    case customizeTitle, customizeHome, customizeAway
    case menuTraining, menuCareer
    case trainingTitle, trainingScore
    case careerTitle, careerLocked, careerWon, careerPlay, careerStage
    case goalTargetTitle, goalTargetNone, goalTargetScope
}
