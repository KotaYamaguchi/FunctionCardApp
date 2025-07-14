//
//  DataManager.swift
//  Function Card App
//
//  Created by 山口昂大 on 2025/07/14.
//

import Foundation
import SwiftUI
import Combine
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var mechanismBlocks: [WrapperBlock] = []
    @Published var appearanceBlocks: [WrapperBlock] = []
    @Published var mechanismContents: [WrappedBlock] = []
    @Published var appearanceContents: [WrappedBlock] = []
    
    private let userDefaults = UserDefaults.standard
    
    // UserDefaultsのキー
    private enum Keys {
        static let mechanismBlocks = "mechanismBlocks"
        static let appearanceBlocks = "appearanceBlocks"
        static let mechanismContents = "mechanismContents"
        static let appearanceContents = "appearanceContents"
    }
    
    private init() {
        loadData()
    }
    
    // MARK: - データ保存
    func saveData() {
        saveWrapperBlocks(mechanismBlocks, key: Keys.mechanismBlocks)
        saveWrapperBlocks(appearanceBlocks, key: Keys.appearanceBlocks)
        saveWrappedBlocks(mechanismContents, key: Keys.mechanismContents)
        saveWrappedBlocks(appearanceContents, key: Keys.appearanceContents)
    }
    
    private func saveWrapperBlocks(_ blocks: [WrapperBlock], key: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(blocks)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to save WrapperBlocks: \(error)")
        }
    }
    
    private func saveWrappedBlocks(_ blocks: [WrappedBlock], key: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(blocks)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to save WrappedBlocks: \(error)")
        }
    }
    
    // MARK: - データ読み込み
    private func loadData() {
        mechanismBlocks = loadWrapperBlocks(key: Keys.mechanismBlocks)
        appearanceBlocks = loadWrapperBlocks(key: Keys.appearanceBlocks)
        mechanismContents = loadWrappedBlocks(key: Keys.mechanismContents)
        appearanceContents = loadWrappedBlocks(key: Keys.appearanceContents)
        
        // 初回起動時のデフォルトデータ
        if mechanismBlocks.isEmpty && mechanismContents.isEmpty {
//            loadDefaultData()
        }
    }
    
    private func loadWrapperBlocks(key: String) -> [WrapperBlock] {
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }
        
        let decoder = JSONDecoder()
        do {
            let blocks = try decoder.decode([WrapperBlock].self, from: data)
            return blocks
        } catch {
            print("Failed to load WrapperBlocks: \(error)")
            return []
        }
    }
    
    private func loadWrappedBlocks(key: String) -> [WrappedBlock] {
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }
        
        let decoder = JSONDecoder()
        do {
            let blocks = try decoder.decode([WrappedBlock].self, from: data)
            return blocks
        } catch {
            print("Failed to load WrappedBlocks: \(error)")
            return []
        }
    }
    
    // MARK: - デフォルトデータ
    private func loadDefaultData() {
        mechanismBlocks = [
            WrapperBlock.create(
                position: CGPoint(x: 180, y: 180),
                text: "ブロックA",
                backText: "ブロックA裏",
                group: .function,
                wrappedBlocks: [
                    WrappedBlock.create(position: .zero, text: "A-1", backText: "A-1裏", group: .function),
                    WrappedBlock.create(position: .zero, text: "A-2", backText: "A-2裏", group: .function)
                ]
            ),
            WrapperBlock.create(
                position: CGPoint(x: 570, y: 180),
                text: "ブロックB",
                backText: "ブロックB裏",
                group: .component,
                wrappedBlocks: [
                    WrappedBlock.create(position: .zero, text: "B-1", backText: "B-1裏", group: .component),
                    WrappedBlock.create(position: .zero, text: "B-2", backText: "B-2裏", group: .component)
                ]
            ),
            WrapperBlock.create(
                position: CGPoint(x: 180, y: 120),
                text: "ブロックC",
                backText: "ブロックC裏",
                group: .button,
                wrappedBlocks: [
                    WrappedBlock.create(position: .zero, text: "C-1", backText: "C-1裏", group: .button),
                    WrappedBlock.create(position: .zero, text: "C-2", backText: "C-2裏", group: .button)
                ]
            )
        ]
        
        mechanismContents = [
            WrappedBlock.create(
                position: CGPoint(x: 120, y: 120),
                text: "コンテンツ1",
                backText: "裏1",
                group: .other
            ),
            WrappedBlock.create(
                position: CGPoint(x: 300, y: 150),
                text: "コンテンツ2",
                backText: "裏2",
                group: .stack
            ),
            WrappedBlock.create(
                position: CGPoint(x: 480, y: 240),
                text: "コンテンツ3",
                backText: "裏3",
                group: .button
            ),
            WrappedBlock.create(
                position: CGPoint(x: 180, y: 390),
                text: "コンテンツ4",
                backText: "裏4",
                group: .component
            ),
            WrappedBlock.create(
                position: CGPoint(x: 390, y: 480),
                text: "コンテンツ5",
                backText: "裏5",
                group: .function
            )
        ]
        
        saveData()
    }
    
    // MARK: - ブロック操作
    func addWrapperBlock(_ block: WrapperBlock, to page: CanvasView.CanvasPage) {
        if page == .mechanism {
            mechanismBlocks.append(block)
        } else {
            appearanceBlocks.append(block)
        }
        saveData()
    }
    
    func addWrappedBlock(_ block: WrappedBlock, to page: CanvasView.CanvasPage) {
        if page == .mechanism {
            mechanismContents.append(block)
        } else {
            appearanceContents.append(block)
        }
        saveData()
    }
    
    func deleteWrapperBlock(id: UUID, from page: CanvasView.CanvasPage) {
        if page == .mechanism {
            mechanismBlocks.removeAll { $0.id == id }
        } else {
            appearanceBlocks.removeAll { $0.id == id }
        }
        saveData()
    }
    
    func deleteWrappedBlock(id: UUID, from page: CanvasView.CanvasPage) {
        if page == .mechanism {
            mechanismContents.removeAll { $0.id == id }
        } else {
            appearanceContents.removeAll { $0.id == id }
        }
        saveData()
    }
    
    func updateWrapperBlock(_ block: WrapperBlock, in page: CanvasView.CanvasPage) {
        if page == .mechanism {
            if let index = mechanismBlocks.firstIndex(where: { $0.id == block.id }) {
                mechanismBlocks[index] = block
            }
        } else {
            if let index = appearanceBlocks.firstIndex(where: { $0.id == block.id }) {
                appearanceBlocks[index] = block
            }
        }
        saveData()
    }
    
    func updateWrappedBlock(_ block: WrappedBlock, in page: CanvasView.CanvasPage) {
        if page == .mechanism {
            if let index = mechanismContents.firstIndex(where: { $0.id == block.id }) {
                mechanismContents[index] = block
            }
        } else {
            if let index = appearanceContents.firstIndex(where: { $0.id == block.id }) {
                appearanceContents[index] = block
            }
        }
        saveData()
    }
    
    // MARK: - 一括更新メソッド（CanvasViewで使用）
    func updateMechanismBlocks(_ blocks: [WrapperBlock]) {
        mechanismBlocks = blocks
        saveData()
    }
    
    func updateAppearanceBlocks(_ blocks: [WrapperBlock]) {
        appearanceBlocks = blocks
        saveData()
    }
    
    func updateMechanismContents(_ contents: [WrappedBlock]) {
        mechanismContents = contents
        saveData()
    }
    
    func updateAppearanceContents(_ contents: [WrappedBlock]) {
        appearanceContents = contents
        saveData()
    }
    
    // MARK: - データリセット（開発用）
    func resetAllData() {
        mechanismBlocks.removeAll()
        appearanceBlocks.removeAll()
        mechanismContents.removeAll()
        appearanceContents.removeAll()
        
        // UserDefaultsからも削除
        userDefaults.removeObject(forKey: Keys.mechanismBlocks)
        userDefaults.removeObject(forKey: Keys.appearanceBlocks)
        userDefaults.removeObject(forKey: Keys.mechanismContents)
        userDefaults.removeObject(forKey: Keys.appearanceContents)
        
        // デフォルトデータを再読み込み
        loadDefaultData()
    }
    
    // MARK: - データエクスポート/インポート（将来拡張用）
    func exportData() -> String? {
        let exportData = ExportData(
            mechanismBlocks: mechanismBlocks,
            appearanceBlocks: appearanceBlocks,
            mechanismContents: mechanismContents,
            appearanceContents: appearanceContents
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(exportData)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Failed to export data: \(error)")
            return nil
        }
    }
    
    func importData(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else {
            return false
        }
        
        let decoder = JSONDecoder()
        do {
            let importData = try decoder.decode(ExportData.self, from: data)
            
            mechanismBlocks = importData.mechanismBlocks
            appearanceBlocks = importData.appearanceBlocks
            mechanismContents = importData.mechanismContents
            appearanceContents = importData.appearanceContents
            
            saveData()
            return true
        } catch {
            print("Failed to import data: \(error)")
            return false
        }
    }
}

// MARK: - エクスポート/インポート用データ構造
private struct ExportData: Codable {
    let mechanismBlocks: [WrapperBlock]
    let appearanceBlocks: [WrapperBlock]
    let mechanismContents: [WrappedBlock]
    let appearanceContents: [WrappedBlock]
}
