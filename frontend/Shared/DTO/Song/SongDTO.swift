//
//  SongDTO.swift
//  DTO
//
//  Created by Ondřej Wrzecionko on 10.03.2022.
//

import Foundation

struct SongDTO: Decodable {
    let id: Int
    let songBook: SongBookRawDTO
    let name: String
    let text: [SongLineDTO]
    let key: SongKey
    let bpm: Int
    let capo: Int
    let lastEdit: String
    let displayId: Int?
    var note: SongNoteDTO?
}

struct SongLineDTO: Decodable {
    let id: String
    let chords: String?
    let text: String
}

enum SongKey: String, Codable, Equatable, CaseIterable {
    case C_SHARP = "C_SHARP"
    case C = "C"
    case D_FLAT = "D_FLAT"
    case D_SHARP = "D_SHARP"
    case D = "D"
    case E_FLAT = "E_FLAT"
    case E = "E"
    case F_SHARP = "F_SHARP"
    case F = "F"
    case G_FLAT = "G_FLAT"
    case G_SHARP = "G_SHARP"
    case G = "G"
    case A_FLAT = "A_FLAT"
    case A_SHARP = "A_SHARP"
    case A = "A"
    case B_FLAT = "B_FLAT"
    case B = "B"
    
    static let sharps: [SongKey] = [.C, .C_SHARP, .D, .D_SHARP, .E, .F, .F_SHARP, .G, .G_SHARP, .A, .B_FLAT, .B]
    static let onlySharps: [SongKey] = [.C, .C_SHARP, .D, .E_FLAT, .E, .F, .F_SHARP, .G, .G_SHARP, .A, .B_FLAT, .B]
    static let flats: [SongKey] = [.C, .D_FLAT, .D, .E_FLAT, .E, .F, .G_FLAT, .G, .A_FLAT, .A, .B_FLAT, .B]
    static let songKeyCount = 12
}

enum ChordDisplayMode: Int, CaseIterable {
    /// Show chords based on current song key
    case key
    /// Show chords with preference of sharps (C#, F#, G#)
    case sharps
    /// Show chords with preference of flats (Db, Gb, Ab)
    case flats
    /// Hide chords and song BPM / capo information
    case hidden
    
    var localized: String {
        switch self {
        case .key:
            return NSLocalizedString("chord_setting_key", comment: "")
        case .sharps:
            return NSLocalizedString("chord_setting_sharps", comment: "")
        case .flats:
            return NSLocalizedString("chord_setting_flats", comment: "")
        case .hidden:
            return NSLocalizedString("chord_setting_hidden", comment: "")
        }
    }
}

// MARK: - Transposition

extension SongKey {
    var keyPosition: Int {
        switch self {
        case .C:
            return 0
        case .C_SHARP, .D_FLAT:
            return 1
        case .D:
            return 2
        case .D_SHARP, .E_FLAT:
            return 3
        case .E:
            return 4
        case .F:
            return 5
        case .F_SHARP, .G_FLAT:
            return 6
        case .G:
            return 7
        case .G_SHARP, .A_FLAT:
            return 8
        case .A:
            return 9
        case .A_SHARP, .B_FLAT:
            return 10
        case .B:
            return 11
        }
    }
    
    var localized: String {
        switch self {
        case .C, .D, .E, .F, .G, .A:
            return rawValue
        case .C_SHARP:
            return "C#"
        case .D_FLAT:
            return "Db"
        case .D_SHARP:
            return "D#"
        case .E_FLAT:
            return "Eb"
        case .F_SHARP:
            return "F#"
        case .G_FLAT:
            return "Gb"
        case .G_SHARP:
            return "G#"
        case .A_FLAT:
            return "Ab"
        case .A_SHARP:
            return "A#"
        case .B_FLAT:
            return "B"
        case .B:
            return "H"
        }
    }
    
    /// Transpose `songKey` to `steps`. Uses keys based on `keys`
    func transpose(steps: Int, keys: [SongKey]) -> SongKey {
        let position = (keyPosition + steps) %% SongKey.songKeyCount
        return keys[position]
    }
}

infix operator %% : MultiplicationPrecedence
extension Int {
    /// Modulo which gives always positive result in [0, rhs)
    static func %% (lhs: Int, rhs: Int) -> Int {
        ((lhs % rhs) + rhs) % rhs
    }
}
