//
//  BlockManagementView.swift
//  Function Card App
//
//  Created by 山口昂大 on 2025/07/14.
//

import SwiftUI

struct BlockManagementView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @State private var selectedPageId: UUID?
    @State private var selectedBlockType: BlockType = .wrapper
    @State private var showingDeleteAlert = false
    @State private var blockToDelete: (id: UUID, type: BlockType)? = nil
    @State private var editingBlock: EditingBlock? = nil
    @State private var searchText = ""
    @State private var selectedGroup: BlockGroup? = nil
    
    enum BlockType: String, CaseIterable {
        case wrapper = "WrapperBlock"
        case wrapped = "WrappedBlock"
    }
    
    struct EditingBlock: Identifiable {
        let id = UUID()
        let blockId: UUID
        let type: BlockType
        var text: String
        var backText: String
        var group: BlockGroup
        var position: CGPoint
    }
    
    // 現在選択されているページ
    private var selectedPage: Page? {
        guard let selectedPageId = selectedPageId else { return nil }
        return dataManager.pages.first { $0.id == selectedPageId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            VStack(spacing: 16) {
                // ページ選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("ページ選択")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if dataManager.pages.isEmpty {
                        HStack {
                            Text("ページがありません")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    } else {
                        Menu {
                            ForEach(dataManager.pages, id: \.id) { page in
                                Button(page.name) {
                                    selectedPageId = page.id
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedPage?.name ?? "ページを選択")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary, lineWidth: 1)
                            )
                        }
                    }
                }
                
                // ブロックタイプ選択
                Picker("ブロックタイプ選択", selection: $selectedBlockType) {
                    ForEach(BlockType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // 検索とフィルター
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("ブロックを検索...", text: $searchText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Menu {
                        Button("すべて") {
                            selectedGroup = nil
                        }
                        ForEach(BlockGroup.allCases, id: \.self) { group in
                            Button(group.rawValue) {
                                selectedGroup = group
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedGroup?.rawValue ?? "すべて")
                            Image(systemName: "chevron.down")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // ブロック一覧
            if selectedPageId == nil {
                // ページが選択されていない場合
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("ページを選択してください")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    if !dataManager.pages.isEmpty {
                        Button("最初のページを選択") {
                            selectedPageId = dataManager.pages.first?.id
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if selectedBlockType == .wrapper {
                    wrapperBlocksList
                } else {
                    wrappedBlocksList
                }
            }
        }
        .navigationTitle("ブロック管理")
        .navigationBarTitleDisplayMode(.large)
        .alert("ブロックを削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteBlock()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("このブロックを削除しますか？この操作は取り消せません。")
        }
        .sheet(item: $editingBlock) { editing in
            BlockEditView(editingBlock: editing) { updatedBlock in
                updateBlock(updatedBlock)
            }
        }
        .onAppear {
            // 初期ページ選択
            if selectedPageId == nil && !dataManager.pages.isEmpty {
                selectedPageId = dataManager.pages.first?.id
            }
        }
    }
    
    // MARK: - WrapperBlocks一覧（スワイプで削除対応）
    private var wrapperBlocksList: some View {
        List {
            let blocks = filteredWrapperBlocks
            
            if blocks.isEmpty {
                Text("ブロックがありません")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(blocks, id: \.id) { block in
                    WrapperBlockRow(block: block) {
                        editBlock(block)
                    } onDelete: {
                        confirmDelete(blockId: block.id, type: .wrapper)
                    }
                    // スワイプで削除
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            guard let pageId = selectedPageId else { return }
                            dataManager.deleteWrapperBlock(id: block.id, from: pageId)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - WrappedBlocks一覧（スワイプで削除対応）
    private var wrappedBlocksList: some View {
        List {
            let blocks = filteredWrappedBlocks
            
            if blocks.isEmpty {
                Text("ブロックがありません")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(blocks, id: \.id) { block in
                    WrappedBlockRow(block: block) {
                        editBlock(block)
                    } onDelete: {
                        confirmDelete(blockId: block.id, type: .wrapped)
                    }
                    // スワイプで削除
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            guard let pageId = selectedPageId else { return }
                            dataManager.deleteWrappedBlock(id: block.id, from: pageId)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - フィルタリング
    private var filteredWrapperBlocks: [WrapperBlock] {
        guard let page = selectedPage else { return [] }
        let blocks = page.wrapperBlocks
        return blocks.filter { block in
            let matchesSearch = searchText.isEmpty ||
                               block.text.localizedCaseInsensitiveContains(searchText) ||
                               block.backText.localizedCaseInsensitiveContains(searchText)
            let matchesGroup = selectedGroup == nil || block.group == selectedGroup
            return matchesSearch && matchesGroup
        }
    }
    
    private var filteredWrappedBlocks: [WrappedBlock] {
        guard let page = selectedPage else { return [] }
        let blocks = page.wrappedBlocks
        return blocks.filter { block in
            let matchesSearch = searchText.isEmpty ||
                               block.text.localizedCaseInsensitiveContains(searchText) ||
                               block.backText.localizedCaseInsensitiveContains(searchText)
            let matchesGroup = selectedGroup == nil || block.group == selectedGroup
            return matchesSearch && matchesGroup
        }
    }
    
    // MARK: - アクション
    private func editBlock(_ block: WrapperBlock) {
        editingBlock = EditingBlock(
            blockId: block.id,
            type: .wrapper,
            text: block.text,
            backText: block.backText,
            group: block.group,
            position: block.position
        )
    }
    
    private func editBlock(_ block: WrappedBlock) {
        editingBlock = EditingBlock(
            blockId: block.id,
            type: .wrapped,
            text: block.text,
            backText: block.backText,
            group: block.group,
            position: block.position
        )
    }
    
    private func confirmDelete(blockId: UUID, type: BlockType) {
        blockToDelete = (id: blockId, type: type)
        showingDeleteAlert = true
    }
    
    private func deleteBlock() {
        guard let blockToDelete = blockToDelete,
              let pageId = selectedPageId else { return }
        
        if blockToDelete.type == .wrapper {
            dataManager.deleteWrapperBlock(id: blockToDelete.id, from: pageId)
        } else {
            dataManager.deleteWrappedBlock(id: blockToDelete.id, from: pageId)
        }
        
        self.blockToDelete = nil
    }
    
    private func updateBlock(_ editingBlock: EditingBlock) {
        guard let pageId = selectedPageId else { return }
        
        if editingBlock.type == .wrapper {
            if let page = selectedPage,
               let index = page.wrapperBlocks.firstIndex(where: { $0.id == editingBlock.blockId }) {
                var updatedBlock = page.wrapperBlocks[index]
                updatedBlock.text = editingBlock.text
                updatedBlock.backText = editingBlock.backText
                updatedBlock.group = editingBlock.group
                updatedBlock.color = editingBlock.group.color
                updatedBlock.position = editingBlock.position
                dataManager.updateWrapperBlock(updatedBlock, in: pageId)
            }
        } else {
            if let page = selectedPage,
               let index = page.wrappedBlocks.firstIndex(where: { $0.id == editingBlock.blockId }) {
                var updatedBlock = page.wrappedBlocks[index]
                updatedBlock.text = editingBlock.text
                updatedBlock.backText = editingBlock.backText
                updatedBlock.group = editingBlock.group
                updatedBlock.color = editingBlock.group.color
                updatedBlock.position = editingBlock.position
                dataManager.updateWrappedBlock(updatedBlock, in: pageId)
            }
        }
    }
}

// MARK: - WrapperBlockRow
struct WrapperBlockRow: View {
    let block: WrapperBlock
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // グループカラー
            RoundedRectangle(cornerRadius: 6)
                .fill(block.group.color)
                .frame(width: 8, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(block.text)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(block.group.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(block.group.color.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text(block.backText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text("位置: (\(Int(block.position.x)), \(Int(block.position.y)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(block.wrappedBlocks.count)個の子ブロック")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(width: 32, height: 32)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(width: 32, height: 32)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - WrappedBlockRow
struct WrappedBlockRow: View {
    let block: WrappedBlock
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // グループカラー
            RoundedRectangle(cornerRadius: 6)
                .fill(block.group.color)
                .frame(width: 8, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(block.text)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(block.group.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(block.group.color.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text(block.backText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("位置: (\(Int(block.position.x)), \(Int(block.position.y)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(width: 32, height: 32)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(width: 32, height: 32)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - BlockEditView
struct BlockEditView: View {
    let editingBlock: BlockManagementView.EditingBlock
    let onSave: (BlockManagementView.EditingBlock) -> Void
    
    @State private var text: String
    @State private var backText: String
    @State private var group: BlockGroup
    @State private var positionX: String
    @State private var positionY: String
    @Environment(\.dismiss) private var dismiss
    
    init(editingBlock: BlockManagementView.EditingBlock, onSave: @escaping (BlockManagementView.EditingBlock) -> Void) {
        self.editingBlock = editingBlock
        self.onSave = onSave
        self._text = State(initialValue: editingBlock.text)
        self._backText = State(initialValue: editingBlock.backText)
        self._group = State(initialValue: editingBlock.group)
        self._positionX = State(initialValue: String(Int(editingBlock.position.x)))
        self._positionY = State(initialValue: String(Int(editingBlock.position.y)))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("表面テキスト", text: $text)
                    TextField("裏面テキスト", text: $backText)
                }
                
                Section("グループ") {
                    Picker("グループ", selection: $group) {
                        ForEach(BlockGroup.allCases, id: \.self) { group in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(group.color)
                                    .frame(width: 16, height: 16)
                                Text(group.rawValue)
                            }
                            .tag(group)
                        }
                    }
                }
                
                Section("位置") {
                    HStack {
                        Text("X座標")
                        TextField("X", text: $positionX)
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("Y座標")
                        TextField("Y", text: $positionY)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("ブロック編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveBlock()
                    }
                }
            }
        }
    }
    
    private func saveBlock() {
        guard let x = Double(positionX), let y = Double(positionY) else {
            return
        }
        
        var updatedBlock = editingBlock
        updatedBlock.text = text
        updatedBlock.backText = backText
        updatedBlock.group = group
        updatedBlock.position = CGPoint(x: x, y: y)
        
        onSave(updatedBlock)
        dismiss()
    }
}

#Preview {
    NavigationView {
        BlockManagementView()
    }
}
