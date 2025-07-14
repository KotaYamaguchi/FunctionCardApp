//
//  BlockStructures.swift
//  Function Card App
//
//  Created by 山口昂大 on 2025/07/14.
//

import Foundation
import SwiftUI

// MARK: - Page構造体
struct Page: Identifiable, Codable,Equatable {
    let id: UUID
    var name: String
    var wrapperBlocks: [WrapperBlock]
    var wrappedBlocks: [WrappedBlock]
    
    init(id: UUID = UUID(), name: String, wrapperBlocks: [WrapperBlock] = [], wrappedBlocks: [WrappedBlock] = []) {
        self.id = id
        self.name = name
        self.wrapperBlocks = wrapperBlocks
        self.wrappedBlocks = wrappedBlocks
    }
}

extension Page {
    static func == (lhs: Page, rhs: Page) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.wrapperBlocks == rhs.wrapperBlocks &&
               lhs.wrappedBlocks == rhs.wrappedBlocks
    }
}

// MARK: - BlockGroup列挙型
enum BlockGroup: String, CaseIterable, Codable {
    case function = "関数"
    case component = "コンポーネント"
    case button = "ボタン"
    case stack = "Stack"
    case other = "その他"
    
    // グループごとの専用カラー
    var color: Color {
        switch self {
        case .function:
            return Color(red: 0.2, green: 0.6, blue: 1.0) // 明るい青
        case .component:
            return Color(red: 0.3, green: 0.8, blue: 0.3) // 明るい緑
        case .button:
            return Color(red: 1.0, green: 0.4, blue: 0.4) // 明るい赤
        case .stack:
            return Color(red: 0.8, green: 0.6, blue: 1.0) // 明るい紫
        case .other:
            return Color(red: 0.9, green: 0.7, blue: 0.3) // 明るいオレンジ
        }
    }
    
    // カラーの説明文
    var colorDescription: String {
        switch self {
        case .function:
            return "ブルー"
        case .component:
            return "グリーン"
        case .button:
            return "レッド"
        case .stack:
            return "パープル"
        case .other:
            return "オレンジ"
        }
    }
}

// MARK: - WrapperBlock構造体
struct WrapperBlock: Identifiable, Codable, Equatable {
    let id: UUID
    var position: CGPoint
    var offset: CGSize = .zero
    var text: String
    var backText: String
    var color: Color
    var isFlipped: Bool
    var group: BlockGroup
    var wrappedBlocks: [WrappedBlock]
    
    init(id: UUID = UUID(),
         position: CGPoint,
         offset: CGSize = .zero,
         text: String,
         backText: String,
         color: Color,
         isFlipped: Bool = false,
         group: BlockGroup,
         wrappedBlocks: [WrappedBlock] = []) {
        self.id = id
        self.position = position
        self.offset = offset
        self.text = text
        self.backText = backText
        self.color = color
        self.isFlipped = isFlipped
        self.group = group
        self.wrappedBlocks = wrappedBlocks
    }
    
    static func == (lhs: WrapperBlock, rhs: WrapperBlock) -> Bool {
        return lhs.id == rhs.id &&
               lhs.position == rhs.position &&
               lhs.offset == rhs.offset &&
               lhs.text == rhs.text &&
               lhs.backText == rhs.backText &&
               lhs.isFlipped == rhs.isFlipped &&
               lhs.group == rhs.group &&
               lhs.wrappedBlocks == rhs.wrappedBlocks &&
               lhs.color.description == rhs.color.description
    }
    
    // MARK: - Codable対応
    private enum CodingKeys: String, CodingKey {
        case id, position, offset, text, backText, isFlipped, group, wrappedBlocks
        case colorRed, colorGreen, colorBlue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        position = try container.decode(CGPoint.self, forKey: .position)
        offset = try container.decodeIfPresent(CGSize.self, forKey: .offset) ?? .zero
        text = try container.decode(String.self, forKey: .text)
        backText = try container.decode(String.self, forKey: .backText)
        isFlipped = try container.decode(Bool.self, forKey: .isFlipped)
        group = try container.decode(BlockGroup.self, forKey: .group)
        wrappedBlocks = try container.decode([WrappedBlock].self, forKey: .wrappedBlocks)
        
        // カラー情報を復元
        if let red = try? container.decode(Double.self, forKey: .colorRed),
           let green = try? container.decode(Double.self, forKey: .colorGreen),
           let blue = try? container.decode(Double.self, forKey: .colorBlue) {
            color = Color(red: red, green: green, blue: blue)
        } else {
            // フォールバック: グループから色を取得
            color = group.color
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(position, forKey: .position)
        try container.encode(offset, forKey: .offset)
        try container.encode(text, forKey: .text)
        try container.encode(backText, forKey: .backText)
        try container.encode(isFlipped, forKey: .isFlipped)
        try container.encode(group, forKey: .group)
        try container.encode(wrappedBlocks, forKey: .wrappedBlocks)
        
        // カラー情報を分解して保存
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        try container.encode(Double(red), forKey: .colorRed)
        try container.encode(Double(green), forKey: .colorGreen)
        try container.encode(Double(blue), forKey: .colorBlue)
    }
}

// MARK: - WrappedBlock構造体
struct WrappedBlock: Identifiable, Equatable, Codable {
    let id: UUID
    var position: CGPoint
    var offset: CGSize = .zero
    var text: String
    var backText: String
    var color: Color
    var isFlipped: Bool
    var group: BlockGroup
    
    init(id: UUID = UUID(),
         position: CGPoint,
         offset: CGSize = .zero,
         text: String,
         backText: String,
         color: Color,
         isFlipped: Bool = false,
         group: BlockGroup) {
        self.id = id
        self.position = position
        self.offset = offset
        self.text = text
        self.backText = backText
        self.color = color
        self.isFlipped = isFlipped
        self.group = group
    }
    
    // MARK: - Equatable実装
    static func == (lhs: WrappedBlock, rhs: WrappedBlock) -> Bool {
        return lhs.id == rhs.id &&
               lhs.position == rhs.position &&
               lhs.offset == rhs.offset &&
               lhs.text == rhs.text &&
               lhs.backText == rhs.backText &&
               lhs.isFlipped == rhs.isFlipped &&
               lhs.group == rhs.group
    }
    
    // MARK: - Codable対応
    private enum CodingKeys: String, CodingKey {
        case id, position, offset, text, backText, isFlipped, group
        case colorRed, colorGreen, colorBlue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        position = try container.decode(CGPoint.self, forKey: .position)
        offset = try container.decodeIfPresent(CGSize.self, forKey: .offset) ?? .zero
        text = try container.decode(String.self, forKey: .text)
        backText = try container.decode(String.self, forKey: .backText)
        isFlipped = try container.decode(Bool.self, forKey: .isFlipped)
        group = try container.decode(BlockGroup.self, forKey: .group)
        
        // カラー情報を復元
        if let red = try? container.decode(Double.self, forKey: .colorRed),
           let green = try? container.decode(Double.self, forKey: .colorGreen),
           let blue = try? container.decode(Double.self, forKey: .colorBlue) {
            color = Color(red: red, green: green, blue: blue)
        } else {
            // フォールバック: グループから色を取得
            color = group.color
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(position, forKey: .position)
        try container.encode(offset, forKey: .offset)
        try container.encode(text, forKey: .text)
        try container.encode(backText, forKey: .backText)
        try container.encode(isFlipped, forKey: .isFlipped)
        try container.encode(group, forKey: .group)
        
        // カラー情報を分解して保存
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        try container.encode(Double(red), forKey: .colorRed)
        try container.encode(Double(green), forKey: .colorGreen)
        try container.encode(Double(blue), forKey: .colorBlue)
    }
}

// MARK: - CGPoint, CGSizeのCodable拡張
extension CGPoint: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    private enum CodingKeys: String, CodingKey {
        case x, y
    }
}

extension CGSize: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }
    
    private enum CodingKeys: String, CodingKey {
        case width, height
    }
}

// MARK: - ブロック作成ヘルパー
extension WrapperBlock {
    /// グループに基づいて自動的にカラーを設定するコンビニエンスイニシャライザ
    static func create(position: CGPoint,
                      text: String,
                      backText: String,
                      group: BlockGroup,
                      wrappedBlocks: [WrappedBlock] = []) -> WrapperBlock {
        return WrapperBlock(
            position: position,
            text: text,
            backText: backText,
            color: group.color,
            group: group,
            wrappedBlocks: wrappedBlocks
        )
    }
}

extension WrappedBlock {
    /// グループに基づいて自動的にカラーを設定するコンビニエンスイニシャライザ
    static func create(position: CGPoint,
                      text: String,
                      backText: String,
                      group: BlockGroup) -> WrappedBlock {
        return WrappedBlock(
            position: position,
            text: text,
            backText: backText,
            color: group.color,
            group: group
        )
    }
}
