//
//  BlockManagementView.swift
//  Function Card App
//
//  Created by 山口昂大 on 2025/07/14.
//

import SwiftUI

struct BlockManagementView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @State private var selectedPage: CanvasView.CanvasPage = .mechanism
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
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            VStack(spacing: 16) {
                // ページ選択
                Picker("ページ選択", selection: $selectedPage) {
                    ForEach(CanvasView.CanvasPage.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
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
            if selectedBlockType == .wrapper {
                wrapperBlocksList
            } else {
                wrappedBlocksList
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
                            dataManager.deleteWrapperBlock(id: block.id, from: selectedPage)
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
                            dataManager.deleteWrappedBlock(id: block.id, from: selectedPage)
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
        let blocks = selectedPage == .mechanism ? dataManager.mechanismBlocks : dataManager.appearanceBlocks
        return blocks.filter { block in
            let matchesSearch = searchText.isEmpty ||
                               block.text.localizedCaseInsensitiveContains(searchText) ||
                               block.backText.localizedCaseInsensitiveContains(searchText)
            let matchesGroup = selectedGroup == nil || block.group == selectedGroup
            return matchesSearch && matchesGroup
        }
    }
    
    private var filteredWrappedBlocks: [WrappedBlock] {
        let blocks = selectedPage == .mechanism ? dataManager.mechanismContents : dataManager.appearanceContents
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
        guard let blockToDelete = blockToDelete else { return }
        
        if blockToDelete.type == .wrapper {
            dataManager.deleteWrapperBlock(id: blockToDelete.id, from: selectedPage)
        } else {
            dataManager.deleteWrappedBlock(id: blockToDelete.id, from: selectedPage)
        }
        
        self.blockToDelete = nil
    }
    
    private func updateBlock(_ editingBlock: EditingBlock) {
        if editingBlock.type == .wrapper {
            let blocks = selectedPage == .mechanism ? dataManager.mechanismBlocks : dataManager.appearanceBlocks
            if let index = blocks.firstIndex(where: { $0.id == editingBlock.blockId }) {
                var updatedBlock = blocks[index]
                updatedBlock.text = editingBlock.text
                updatedBlock.backText = editingBlock.backText
                updatedBlock.group = editingBlock.group
                updatedBlock.color = editingBlock.group.color
                updatedBlock.position = editingBlock.position
                dataManager.updateWrapperBlock(updatedBlock, in: selectedPage)
            }
        } else {
            let blocks = selectedPage == .mechanism ? dataManager.mechanismContents : dataManager.appearanceContents
            if let index = blocks.firstIndex(where: { $0.id == editingBlock.blockId }) {
                var updatedBlock = blocks[index]
                updatedBlock.text = editingBlock.text
                updatedBlock.backText = editingBlock.backText
                updatedBlock.group = editingBlock.group
                updatedBlock.color = editingBlock.group.color
                updatedBlock.position = editingBlock.position
                dataManager.updateWrappedBlock(updatedBlock, in: selectedPage)
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

#Preview {
    NavigationView {
        BlockManagementView()
    }
}
