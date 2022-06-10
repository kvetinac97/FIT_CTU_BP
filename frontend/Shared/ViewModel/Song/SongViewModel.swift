//
//  SongViewModel.swift
//  ViewModel
//
//  Created by Ondřej Wrzecionko on 23.03.2022.
//

import Foundation

final class SongViewModel: ObservableObject {
    
    // MARK: - Public properties
    
    @Published var editSong: Song? = nil
    
    @Published var song: Song? = nil {
        didSet {
            guard let song = song else { return }
            textSize = songService.textSize(for: song)
            capo = songService.capo(for: song)
        }
    }
    
    // MARK: - Popover properties
    
    @Published var isSongSettingsPopoverShown: Bool = false
    
    @Published var capo: Int = 0 {
        didSet {
            guard let song = song else { return }
            songService.capo(capo, for: song)
        }
    }
    
    @Published var textSize: Double = 0 {
        didSet {
            guard let song = song else { return }
            songService.textSize(textSize, for: song)
        }
    }
    @Published var maxLineChars: Int? = nil
    
    // MARK: - Song width reader properties
    
    @Published var textWidth: Double? = nil {
        didSet {
            guard let textWidth = textWidth, let viewWidth = viewWidth else { return }
            maxLineChars = Int((viewWidth - 3 * Constants.songViewPadding) / textWidth)
        }
    }
    @Published var viewWidth: Double? = nil {
        didSet {
            guard let textWidth = textWidth, let viewWidth = viewWidth else { return }
            maxLineChars = Int((viewWidth - 3 * Constants.songViewPadding) / textWidth)
        }
    }
    
    // MARK: - Private properties
    
    private let appState: AppState
    private let songService: SongServicing
    
    // MARK: - Init
    
    init(context: HasAppState & HasSongService) {
        appState = context.appState
        songService = context.songService
    }
    
    // MARK: - Public functions
    
    func divide(line: SongLine, with maxCharacters: Int) -> [SongLine] {
        // Prepare texts
        let chords = line.chords ?? "", text = line.text
        
        // No need to cut (chords overflow is wanted)
        if text.count <= maxCharacters || maxCharacters <= 5 {
            return [line]
        }
        
        // Fill chords and text with spaces until `maxCharacters`
        let chordsFill = chords.fill(maxCharacters: maxCharacters),
            chordsPref = chordsFill.prefix(maxCharacters),
            textFill = text.fill(maxCharacters: maxCharacters),
            textPref = textFill.prefix(maxCharacters)
        
        // Find position
        let prefixEnd: Int, suffixStart: Int
        
        // Found successfully
        if let splitPosition = findSplitPosition(textPrefix: textPref, chordsPrefix: chordsPref) {
            prefixEnd = splitPosition
            suffixStart = splitPosition + 1
        }
        // Did not find
        else {
            prefixEnd = maxCharacters
            suffixStart = maxCharacters
        }

        // Return first part and recursively split the rest
        return [SongLine(
            id: line.id + "_1",
            chords: chordsFill.prefix(prefixEnd).strValue,
            text: textFill.prefix(prefixEnd).strValue ?? ""
        )] + divide(
            line: SongLine(
                id: line.id + "_2",
                chords: chordsFill.suffix(chordsFill.count - suffixStart).strValue,
                text: textFill.suffix(textFill.count - suffixStart).strValue ?? ""
            ),
            with: maxCharacters
        )
    }
    
    /// Finds the ideal split position for the two prefixes, that meets following requirements:
    /// 1) both prefixes contain a space character at this position
    /// 2) it is the furthest position meeting this requirement
    /// if no such position exists, text is just cut in two halves disregarding spaces (represented by `nil`)
    func findSplitPosition(
        textPrefix: Substring.SubSequence,
        chordsPrefix: Substring.SubSequence
    ) -> Int? {
        guard var chordsIndex = chordsPrefix.lastSpaceIndex(),
              var textIndex = textPrefix.lastSpaceIndex() else { return nil }
        
        // Move positions as long as we can
        while chordsIndex != textIndex {
            if chordsIndex < textIndex {
                if let index = textPrefix.prefix(chordsIndex + 1).lastSpaceIndex() {
                    textIndex = index
                }
                else { break }
            }
            if textIndex < chordsIndex {
                if let index = chordsPrefix.prefix(textIndex + 1).lastSpaceIndex() {
                    chordsIndex = index
                }
                else { break }
            }
        }
            
        // If both positions are same, we finished successfully
        return textIndex == chordsIndex ? textIndex : nil
    }
    
    /// Shows text with information
    /// based on appState `hidden` setting
    func textWithInformation(song: Song) -> [SongLine] {
        let hideChords = appState.chordDisplayMode == .hidden
        let note = song.note?.notes ?? ""
        let songInformation = (song.bpm == 0 || song.bpm == 999 || hideChords ? [] : ["🎵 \(song.bpm)"])
            + (song.capo == 0 || hideChords ? [] : ["capo \(song.capo)"])
            + (note.isEmpty ? [] : [note])
        if songInformation.isEmpty { return song.text }
        return [SongLine(
            id: "songinfo",
            chords: nil,
            text: songInformation.joined(separator: ", ")
        )] + song.text
    }
    
    /// Applies transposition on given chords
    /// if chords are hidden, return `nil`
    func transposeAndHide(line: SongLine, song: Song) -> String? {
        guard let chords = line.chords else { return nil }
        let original = chords.split(separator: " ", omittingEmptySubsequences: false)
        let songKeyPosition = (song.key.keyPosition + capo) %% 12
        
        let keys: [SongKey]
        switch appState.chordDisplayMode {
        case .key:
            let useFlats = [SongKey.F, SongKey.B_FLAT, SongKey.E_FLAT, SongKey.A_FLAT]
                .contains(SongKey.flats[songKeyPosition])
            keys = useFlats ? SongKey.flats : SongKey.sharps
        case .sharps:
            keys = SongKey.onlySharps
        case .flats:
            keys = SongKey.flats
        case .hidden:
            return nil
        }
        
        let transposed = original.map { chordStr -> (String, String) in
            let chord = String(chordStr)
            for key in SongKey.allCases {
                let transposed = key.transpose(steps: capo, keys: keys)
                if chord.replacingOccurrences(of: "(", with: "").starts(with: key.localized) {
                    return (chord, chord.replacingOccurrences(of: key.localized, with: transposed.localized))
                }
            }
            return (chord, chord)
        }
        
        var skip = 0
        let result = transposed.compactMap { pair -> String? in
            let originalStr = pair.0, transposedStr = pair.1
            // Skipping empty strings
            if skip > 0 && transposedStr.isEmpty {
                skip -= 1
                return nil
            }
            
            // OK, transposition did not change number of characters
            if originalStr.count == transposedStr.count {
                return transposedStr
            }
            
            // Number of characters is now shorter, add space
            if transposedStr.count < originalStr.count {
                return transposedStr + " "
            }
            
            // Number of characters is now longer, remove space if we can
            skip += 1
            return transposedStr
        }
            
        return result.joined(separator: " ")
    }
    
    // MARK: - Constants
    
    enum Constants {
        static let songViewPadding: Double = 20
    }
}

// MARK: - Helper extensions

extension Substring {
    /// Creates String value without trailing whitespaces, `nil` if created text is whitespace only
    var strValue: String? {
        let str = String(self).replacingOccurrences(of: "-*$", with: "", options: .regularExpression)
        return str.contains(where: { !$0.isWhitespace }) ? str : nil
    }
}

extension String {
    /// Fills given String with spaces until given character count is met
    func fill(maxCharacters: Int) -> String {
        count >= maxCharacters ? self : self + String(repeating: " ", count: maxCharacters - count)
    }
}

extension Substring.SubSequence {
    /// Helper function to get last space character index as `Int`
    func lastSpaceIndex() -> Int? {
        guard let index = lastIndex(where: { $0 == " " }) else { return nil }
        return distance(from: startIndex, to: index)
    }
}
