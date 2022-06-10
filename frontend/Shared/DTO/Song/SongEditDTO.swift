//
//  SongEditDTO.swift
//  DTO
//
//  Created by Ondřej Wrzecionko on 30.03.2022.
//

import Foundation

struct SongEditDTO: Encodable {
    let name: String
    let songBookId: Int
    let key: SongKey
    let bpm: Int
    let capo: Int
    let text: String
    let displayId: Int?
}

struct SongNoteEditDTO: Encodable {
    let notes: String
    let capo: Int
}
