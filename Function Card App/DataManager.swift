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
    
    @Published var pages: [Page] = []
    
    // 下位互換性のための従来のプロパティ（廃止予定）
    @Published var mechanismBlocks: [WrapperBlock] = []
    @Published var appearanceBlocks: [WrapperBlock] = []
    @Published var mechanismContents: [WrappedBlock] = []
    @Published var appearanceContents: [WrappedBlock] = []
    
    private let userDefaults = UserDefaults.standard
    
    // UserDefaultsのキー
    private enum Keys {
        static let pages = "pages"
        // 従来のキー（マイグレーション用）
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
        savePages()
    }
    
    private func savePages() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(pages)
            userDefaults.set(data, forKey: Keys.pages)
        } catch {
            print("Failed to save Pages: \(error)")
        }
    }
    
    // MARK: - データ読み込み
    private func loadData() {
        // まず新しいPages形式での読み込みを試す
        if loadPages() {
            print("Pages loaded successfully")
        } else {
            // 従来形式からのマイグレーション
            print("Migrating from legacy format")
            migrateLegacyData()
        }
        
        // 初回起動時のデフォルトデータ
        if pages.isEmpty {
            loadDefaultData()
        }
    }
    
    private func loadPages() -> Bool {
        guard let data = userDefaults.data(forKey: Keys.pages) else {
            return false
        }
        
        let decoder = JSONDecoder()
        do {
            let loadedPages = try decoder.decode([Page].self, from: data)
            pages = loadedPages
            return true
        } catch {
            print("Failed to load Pages: \(error)")
            return false
        }
    }
    
    // MARK: - 従来データからのマイグレーション
    private func migrateLegacyData() {
        mechanismBlocks = loadWrapperBlocks(key: Keys.mechanismBlocks)
        appearanceBlocks = loadWrapperBlocks(key: Keys.appearanceBlocks)
        mechanismContents = loadWrappedBlocks(key: Keys.mechanismContents)
        appearanceContents = loadWrappedBlocks(key: Keys.appearanceContents)
        
        // 従来のデータをPagesに変換
        if !mechanismBlocks.isEmpty || !mechanismContents.isEmpty {
            let mechanismPage = Page(
                name: "仕組みページ",
                wrapperBlocks: mechanismBlocks,
                wrappedBlocks: mechanismContents
            )
            pages.append(mechanismPage)
        }
        
        if !appearanceBlocks.isEmpty || !appearanceContents.isEmpty {
            let appearancePage = Page(
                name: "見た目ページ",
                wrapperBlocks: appearanceBlocks,
                wrappedBlocks: appearanceContents
            )
            pages.append(appearancePage)
        }
        
        // 新形式で保存
        if !pages.isEmpty {
            savePages()
            // 従来のデータを削除
            userDefaults.removeObject(forKey: Keys.mechanismBlocks)
            userDefaults.removeObject(forKey: Keys.appearanceBlocks)
            userDefaults.removeObject(forKey: Keys.mechanismContents)
            userDefaults.removeObject(forKey: Keys.appearanceContents)
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
        let mechanismPage = Page(
            name: "仕組みページ",
            wrapperBlocks: [
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
                )
            ],
            wrappedBlocks: [
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
                )
            ]
        )
        
        let appearancePage = Page(
            name: "見た目ページ",
            wrapperBlocks: [],
            wrappedBlocks: []
        )
        
        pages = [mechanismPage, appearancePage]
        saveData()
    }
    
    // MARK: - ページ操作
    func addPage(name: String) {
        let newPage = Page(name: name)
        pages.append(newPage)
        saveData()
    }
    
    func deletePage(id: UUID) {
        pages.removeAll { $0.id == id }
        saveData()
    }
    
    func updatePageName(id: UUID, newName: String) {
        if let index = pages.firstIndex(where: { $0.id == id }) {
            pages[index].name = newName
            saveData()
        }
    }
    
    func getPage(id: UUID) -> Page? {
        return pages.first { $0.id == id }
    }
    
    // MARK: - ブロック操作（新しいPage対応）
    func addWrapperBlock(_ block: WrapperBlock, to pageId: UUID) {
        if let index = pages.firstIndex(where: { $0.id == pageId }) {
            pages[index].wrapperBlocks.append(block)
            saveData()
        }
    }
    
    func addWrappedBlock(_ block: WrappedBlock, to pageId: UUID) {
        if let index = pages.firstIndex(where: { $0.id == pageId }) {
            pages[index].wrappedBlocks.append(block)
            saveData()
        }
    }
    
    func deleteWrapperBlock(id: UUID, from pageId: UUID) {
        if let pageIndex = pages.firstIndex(where: { $0.id == pageId }) {
            pages[pageIndex].wrapperBlocks.removeAll { $0.id == id }
            saveData()
        }
    }
    
    func deleteWrappedBlock(id: UUID, from pageId: UUID) {
        if let pageIndex = pages.firstIndex(where: { $0.id == pageId }) {
            pages[pageIndex].wrappedBlocks.removeAll { $0.id == id }
            saveData()
        }
    }
    
    func updateWrapperBlock(_ block: WrapperBlock, in pageId: UUID) {
        if let pageIndex = pages.firstIndex(where: { $0.id == pageId }),
           let blockIndex = pages[pageIndex].wrapperBlocks.firstIndex(where: { $0.id == block.id }) {
            pages[pageIndex].wrapperBlocks[blockIndex] = block
            saveData()
        }
    }
    
    func updateWrappedBlock(_ block: WrappedBlock, in pageId: UUID) {
        if let pageIndex = pages.firstIndex(where: { $0.id == pageId }),
           let blockIndex = pages[pageIndex].wrappedBlocks.firstIndex(where: { $0.id == block.id }) {
            pages[pageIndex].wrappedBlocks[blockIndex] = block
            saveData()
        }
    }
    
    // MARK: - 一括更新メソッド
    func updateWrapperBlocks(_ blocks: [WrapperBlock], in pageId: UUID) {
        if let index = pages.firstIndex(where: { $0.id == pageId }) {
            pages[index].wrapperBlocks = blocks
            saveData()
        }
    }
    
    func updateWrappedBlocks(_ blocks: [WrappedBlock], in pageId: UUID) {
        if let index = pages.firstIndex(where: { $0.id == pageId }) {
            pages[index].wrappedBlocks = blocks
            saveData()
        }
    }
    
    // MARK: - 下位互換性のためのメソッド（廃止予定）
    @available(*, deprecated, message: "Use page-based methods instead")
    func addWrapperBlock(_ block: WrapperBlock, to page: CanvasPage) {
        let targetPageName = page == .mechanism ? "仕組みページ" : "見た目ページ"
        if let targetPage = pages.first(where: { $0.name == targetPageName }) {
            addWrapperBlock(block, to: targetPage.id)
        } else {
            // ページが存在しない場合は作成
            let newPage = Page(name: targetPageName)
            pages.append(newPage)
            addWrapperBlock(block, to: newPage.id)
        }
    }
    
    @available(*, deprecated, message: "Use page-based methods instead")
    func addWrappedBlock(_ block: WrappedBlock, to page: CanvasPage) {
        let targetPageName = page == .mechanism ? "仕組みページ" : "見た目ページ"
        if let targetPage = pages.first(where: { $0.name == targetPageName }) {
            addWrappedBlock(block, to: targetPage.id)
        } else {
            // ページが存在しない場合は作成
            let newPage = Page(name: targetPageName)
            pages.append(newPage)
            addWrappedBlock(block, to: newPage.id)
        }
    }
    
    // MARK: - データリセット
    func resetAllData() {
        pages.removeAll()
        userDefaults.removeObject(forKey: Keys.pages)
        loadDefaultData()
    }
}
// DataManager内に追加
enum CanvasPage: String, CaseIterable {
    case mechanism = "仕組みページ"
    case appearance = "見た目ページ"
}
