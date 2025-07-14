//
//  CanvasView.swift
//  Function Card App
//
//  Created by 山口昂大 on 2025/07/12.
//

import SwiftUI

struct CanvasView: View {
    @ObservedObject private var dataManager = DataManager.shared
    
    // ページ関連の状態
    @State private var selectedPageId: UUID?
    @State private var showingPageManager = false
    @State private var showingAddPage = false
    @State private var newPageName = ""
    
    // 各ページのオフセットとスケールを管理
    @State private var pageOffsets: [UUID: CGSize] = [:]
    @State private var canvasScale: CGFloat = 1.0
    
    // 選択モード関連
    @State private var isSelectionMode: Bool = false
    @State private var selectedWrapperBlocks: Set<UUID> = []
    @State private var selectedWrappedBlocks: Set<UUID> = []
    
    // ドラッグ中の状態管理
    @State private var isDraggingSelected: Bool = false
    @State private var draggedBlockId: UUID? = nil
    
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    
    @State private var showEnlargedText: Bool = false
    @State private var enlargedText: String = ""
    @State private var enlargedTextColor: Color = .primary
    @State private var enlargedBackgroundColor: Color = .white
    
    @State private var dropTargetedWrapperIndex: Int? = nil
    
    private let scaleStep: CGFloat = 0.25
    private let minScale: CGFloat = 0.25
    private let maxScale: CGFloat = 3.0
    private let gridSize: CGFloat = 30
    
    // 現在のページを取得
    private var currentPage: Page? {
        guard let selectedPageId = selectedPageId else { return nil }
        return dataManager.pages.first { $0.id == selectedPageId }
    }
    
    // 現在のページのオフセット
    private var currentOffset: CGSize {
        guard let selectedPageId = selectedPageId else { return .zero }
        return pageOffsets[selectedPageId] ?? .zero
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 上部のコントロール
                HStack {
                    // ページ選択
                    pageSelector
                    
                    Spacer()
                    
                    // ページ管理ボタン
                    Button(action: { showingPageManager = true }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("ページ管理")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple)
                        )
                    }
                    
                    // 管理画面ボタン
                    NavigationLink(destination: BlockManagementView()) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("管理")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange)
                        )
                    }
                    
                    NavigationLink(destination: AdminView()) {
                        HStack {
                            Image(systemName: "gear")
                            Text("追加")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray)
                        )
                    }
                    
                    // 選択モードボタン
                    Button(action: toggleSelectionMode) {
                        HStack {
                            Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "circle")
                            Text("選択モード")
                        }
                        .foregroundColor(isSelectionMode ? .white : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelectionMode ? Color.blue : Color.clear)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                    
                    // 選択クリアボタン
                    if isSelectionMode && (!selectedWrapperBlocks.isEmpty || !selectedWrappedBlocks.isEmpty) {
                        Button("クリア", action: clearSelection)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // キャンバス
                GeometryReader { geometry in
                    canvasContent(geometry: geometry)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showEnlargedText) {
            ZStack {
                enlargedBackgroundColor.edgesIgnoringSafeArea(.all)
                Text(enlargedText)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(enlargedTextColor)
                    .padding(32)
            }
        }
        .sheet(isPresented: $showingPageManager) {
            PageManagerView(isPresented: $showingPageManager, selectedPageId: $selectedPageId)
        }
        .onAppear {
            initializeSelectedPage()
        }
        .onChange(of: dataManager.pages) { _ in
            // ページが変更された時の処理
            if selectedPageId == nil || !dataManager.pages.contains(where: { $0.id == selectedPageId }) {
                initializeSelectedPage()
            }
        }
    }
    
    // MARK: - ページセレクター
    private var pageSelector: some View {
        HStack {
            if dataManager.pages.isEmpty {
                Text("ページなし")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
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
                        Text(currentPage?.name ?? "ページを選択")
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - キャンバスコンテンツ
    private func canvasContent(geometry: GeometryProxy) -> some View {
        let combinedGesture = DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                if let selectedPageId = selectedPageId {
                    let currentOffset = pageOffsets[selectedPageId] ?? .zero
                    pageOffsets[selectedPageId] = CGSize(
                        width: currentOffset.width + value.translation.width,
                        height: currentOffset.height + value.translation.height
                    )
                }
            }
            .simultaneously(with:
                MagnificationGesture()
                    .updating($gestureScale) { value, state, _ in
                        state = value
                    }
                    .onEnded { value in
                        canvasScale *= value
                        canvasScale = max(minScale, min(maxScale, canvasScale))
                    }
            )
        
        return ZStack {
            ZStack {
                GridBackgroundView()
                    .ignoresSafeArea()
                
                if let page = currentPage {
                    // WrapperBlocks
                    ForEach(0..<page.wrapperBlocks.count, id: \.self) { index in
                        wrapperBlockView(
                            block: page.wrapperBlocks[index],
                            index: index,
                            isDropTargeted: dropTargetedWrapperIndex == index,
                            isSelected: selectedWrapperBlocks.contains(page.wrapperBlocks[index].id)
                        )
                    }
                    
                    // WrappedBlocks
                    ForEach(0..<page.wrappedBlocks.count, id: \.self) { index in
                        wrappedBlockView(
                            block: page.wrappedBlocks[index],
                            index: index,
                            isSelected: selectedWrappedBlocks.contains(page.wrappedBlocks[index].id)
                        )
                    }
                } else {
                    // ページが選択されていない場合
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("ページを選択してください")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .scaleEffect(canvasScale * gestureScale)
            .offset(x: currentOffset.width + dragOffset.width,
                    y: currentOffset.height + dragOffset.height)
            .gesture(combinedGesture)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // オーバーレイコントロール
            overlayControls
        }
    }
    
    // MARK: - オーバーレイコントロール
    private var overlayControls: some View {
        VStack {
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Button(action: zoomOut) {
                        Image(systemName: "minus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(canvasScale <= minScale ? Color.gray : Color.blue)
                                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                            )
                    }
                    .disabled(canvasScale <= minScale)
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("\(Int(canvasScale * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                        .onTapGesture {
                            resetZoom()
                        }
                    
                    Button(action: zoomIn) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(canvasScale >= maxScale ? Color.gray : Color.blue)
                                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                            )
                    }
                    .disabled(canvasScale >= maxScale)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.trailing, 80)
            }
            Spacer()
            
            // 選択状態の表示
            if isSelectionMode {
                VStack {
                    Spacer()
                    HStack {
                        Text("選択中: \(selectedWrapperBlocks.count + selectedWrappedBlocks.count)個")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.7))
                            )
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    .padding(.leading, 20)
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - ヘルパー関数
    private func initializeSelectedPage() {
        if selectedPageId == nil && !dataManager.pages.isEmpty {
            selectedPageId = dataManager.pages.first?.id
        }
    }
    
    // Grid snapping helper function
    private func snapToGrid(_ point: CGPoint) -> CGPoint {
        let snappedX = round(point.x / gridSize) * gridSize
        let snappedY = round(point.y / gridSize) * gridSize
        return CGPoint(x: snappedX, y: snappedY)
    }
    
    private func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedWrapperBlocks.removeAll()
            selectedWrappedBlocks.removeAll()
        }
    }
    
    private func clearSelection() {
        selectedWrapperBlocks.removeAll()
        selectedWrappedBlocks.removeAll()
    }
    
    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            let newScale = canvasScale + scaleStep
            canvasScale = min(newScale, maxScale)
        }
    }
    
    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            let newScale = canvasScale - scaleStep
            canvasScale = max(newScale, minScale)
        }
    }
    
    private func resetZoom() {
        withAnimation(.easeInOut(duration: 0.3)) {
            canvasScale = 1.0
        }
    }
    
    // MARK: - ブロック操作メソッド
    private func applyOffsetToSelectedBlocks(_ offset: CGSize) {
        guard let pageId = selectedPageId,
              let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }) else { return }
        
        var updatedPage = dataManager.pages[pageIndex]
        
        // WrapperBlocksにオフセットを適用
        for i in updatedPage.wrapperBlocks.indices {
            if selectedWrapperBlocks.contains(updatedPage.wrapperBlocks[i].id) {
                updatedPage.wrapperBlocks[i].offset = offset
            }
        }
        
        // WrappedBlocksにオフセットを適用
        for i in updatedPage.wrappedBlocks.indices {
            if selectedWrappedBlocks.contains(updatedPage.wrappedBlocks[i].id) {
                updatedPage.wrappedBlocks[i].offset = offset
            }
        }
        
        dataManager.pages[pageIndex] = updatedPage
    }
    
    private func commitSelectedBlocksPosition() {
        guard let pageId = selectedPageId,
              let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }) else { return }
        
        var updatedPage = dataManager.pages[pageIndex]
        
        // WrapperBlocksのポジション更新
        for i in updatedPage.wrapperBlocks.indices {
            if selectedWrapperBlocks.contains(updatedPage.wrapperBlocks[i].id) {
                let newPosition = CGPoint(
                    x: updatedPage.wrapperBlocks[i].position.x + updatedPage.wrapperBlocks[i].offset.width,
                    y: updatedPage.wrapperBlocks[i].position.y + updatedPage.wrapperBlocks[i].offset.height
                )
                updatedPage.wrapperBlocks[i].position = snapToGrid(newPosition)
                updatedPage.wrapperBlocks[i].offset = .zero
            }
        }
        
        // WrappedBlocksのポジション更新
        for i in updatedPage.wrappedBlocks.indices {
            if selectedWrappedBlocks.contains(updatedPage.wrappedBlocks[i].id) {
                let newPosition = CGPoint(
                    x: updatedPage.wrappedBlocks[i].position.x + updatedPage.wrappedBlocks[i].offset.width,
                    y: updatedPage.wrappedBlocks[i].position.y + updatedPage.wrappedBlocks[i].offset.height
                )
                updatedPage.wrappedBlocks[i].position = snapToGrid(newPosition)
                updatedPage.wrappedBlocks[i].offset = .zero
            }
        }
        
        dataManager.pages[pageIndex] = updatedPage
        dataManager.saveData()
    }
    
    private func frameForWrapperBlock(_ block: WrapperBlock) -> CGRect {
        let size = CGSize(width: 360, height: 360)
        return CGRect(origin: CGPoint(x: block.position.x, y: block.position.y), size: size)
    }
    
    private func dropAreaForWrapperBlock(_ block: WrapperBlock) -> CGRect {
        let headerHeight: CGFloat = 60
        let blockRowHeight: CGFloat = 30
        let bottomSpace: CGFloat = 30
        let dynamicHeight = headerHeight + CGFloat(block.wrappedBlocks.count) * blockRowHeight + bottomSpace
        let adjustedHeight = ceil(dynamicHeight / 30) * 30
        
        let margin: CGFloat = 20
        
        let centerX = block.position.x + 180
        let centerY = block.position.y + adjustedHeight / 2
        
        let actualLeftTop = CGPoint(
            x: centerX - 180,
            y: centerY - adjustedHeight / 2
        )
        
        let frame = CGRect(
            origin: actualLeftTop,
            size: CGSize(width: 360, height: adjustedHeight)
        )
        
        return frame.insetBy(dx: margin, dy: margin)
    }
    
    private func moveWrappedBlock(in blockIndex: Int, from sourceIndex: Int, direction: MoveDirection) {
        guard let pageId = selectedPageId,
              let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }) else { return }
        
        var page = dataManager.pages[pageIndex]
        guard blockIndex < page.wrapperBlocks.count else { return }
        
        let targetIndex: Int
        switch direction {
        case .up:
            targetIndex = max(0, sourceIndex - 1)
        case .down:
            targetIndex = min(page.wrapperBlocks[blockIndex].wrappedBlocks.count - 1, sourceIndex + 1)
        }
        
        if sourceIndex != targetIndex {
            let movedItem = page.wrapperBlocks[blockIndex].wrappedBlocks.remove(at: sourceIndex)
            page.wrapperBlocks[blockIndex].wrappedBlocks.insert(movedItem, at: targetIndex)
            dataManager.pages[pageIndex] = page
            dataManager.saveData()
        }
    }
    
    enum MoveDirection {
        case up, down
    }
    
    // MARK: - WrapperBlockView
    private func wrapperBlockView(block: WrapperBlock, index: Int, isDropTargeted: Bool, isSelected: Bool) -> some View {
        let headerHeight: CGFloat = 60
        let blockRowHeight: CGFloat = 30
        let bottomSpace: CGFloat = 30
        let dynamicHeight = headerHeight + CGFloat(block.wrappedBlocks.count) * blockRowHeight + bottomSpace
        let adjustedHeight = ceil(dynamicHeight / 30) * 30
        
        return ZStack {
            Rectangle()
                .fill(block.isFlipped ? block.color : Color.white)
                .shadow(color: .gray.opacity(block.isFlipped ? 0.6 : 0.3), radius: 4, x: 0, y: 2)
            
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 6)
                    .opacity(0.7)
                    .animation(.easeInOut(duration: 0.18), value: isDropTargeted)
            }
            
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange, lineWidth: 4)
                    .opacity(0.8)
            }
            
            VStack(spacing: 0) {
                Rectangle()
                    .fill(block.isFlipped ? Color.white : block.color.opacity(0.8))
                    .frame(height: 60)
                    .overlay(
                        HStack {
                            if isSelectionMode {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isSelected ? .orange : .gray)
                                    .font(.system(size: 16))
                            }
                            Text(block.isFlipped ? block.backText : block.text)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(block.isFlipped ? block.color : .white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                        }
                            .padding(.horizontal, 8)
                    )
                
                VStack(spacing: 4) {
                    if !block.wrappedBlocks.isEmpty {
                        ForEach(Array(block.wrappedBlocks.enumerated()), id: \.element.id) { wrappedIndex, content in
                            DraggableRowView(
                                content: content,
                                blockIndex: index,
                                wrappedIndex: wrappedIndex,
                                wrappedBlocks: Binding(
                                    get: {
                                        guard let pageId = selectedPageId,
                                              let page = dataManager.pages.first(where: { $0.id == pageId }),
                                              index < page.wrapperBlocks.count else { return [] }
                                        return page.wrapperBlocks[index].wrappedBlocks
                                    },
                                    set: { newValue in
                                        guard let pageId = selectedPageId,
                                              let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }),
                                              index < dataManager.pages[pageIndex].wrapperBlocks.count else { return }
                                        dataManager.pages[pageIndex].wrapperBlocks[index].wrappedBlocks = newValue
                                        dataManager.saveData()
                                    }),
                                contents: Binding(
                                    get: {
                                        guard let pageId = selectedPageId,
                                              let page = dataManager.pages.first(where: { $0.id == pageId }) else { return [] }
                                        return page.wrappedBlocks
                                    },
                                    set: { newValue in
                                        guard let pageId = selectedPageId,
                                              let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }) else { return }
                                        dataManager.pages[pageIndex].wrappedBlocks = newValue
                                        dataManager.saveData()
                                    }),
                                frameForWrapperBlock: frameForWrapperBlock,
                                parentBlock: block,
                                onMoveUp: {
                                    moveWrappedBlock(in: index, from: wrappedIndex, direction: .up)
                                },
                                onMoveDown: {
                                    moveWrappedBlock(in: index, from: wrappedIndex, direction: .down)
                                },
                                canMoveUp: wrappedIndex > 0,
                                canMoveDown: wrappedIndex < block.wrappedBlocks.count - 1,
                                onEnlargeRequested: { text, textColor, bgColor in
                                    Task{
                                        enlargedText = text
                                        enlargedTextColor = textColor
                                        enlargedBackgroundColor = bgColor
                                        print(enlargedText)
                                    }
                                    showEnlargedText = true
                                }
                            )
                        }
                    }
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
            }
        }
        .frame(width: 360, height: adjustedHeight)
        .position(
            x: block.position.x + block.offset.width,
            y: block.position.y + block.offset.height
        )
        .onTapGesture {
            if isSelectionMode {
                if selectedWrapperBlocks.contains(block.id) {
                    selectedWrapperBlocks.remove(block.id)
                } else {
                    selectedWrapperBlocks.insert(block.id)
                }
            } else {
                guard let pageId = selectedPageId,
                      let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }),
                      index < dataManager.pages[pageIndex].wrapperBlocks.count else { return }
                dataManager.pages[pageIndex].wrapperBlocks[index].isFlipped.toggle()
                dataManager.saveData()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if isSelectionMode {
                        applyOffsetToSelectedBlocks(value.translation)
                    } else {
                        guard let pageId = selectedPageId,
                              let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }),
                              index < dataManager.pages[pageIndex].wrapperBlocks.count else { return }
                        dataManager.pages[pageIndex].wrapperBlocks[index].offset = value.translation
                    }
                }
                .onEnded { value in
                    if isSelectionMode {
                        commitSelectedBlocksPosition()
                    } else {
                        guard let pageId = selectedPageId,
                              let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }),
                              index < dataManager.pages[pageIndex].wrapperBlocks.count else { return }
                        let newPosition = CGPoint(
                            x: dataManager.pages[pageIndex].wrapperBlocks[index].position.x + value.translation.width,
                            y: dataManager.pages[pageIndex].wrapperBlocks[index].position.y + value.translation.height
                        )
                        let snappedPosition = snapToGrid(newPosition)
                        dataManager.pages[pageIndex].wrapperBlocks[index].position = snappedPosition
                        dataManager.pages[pageIndex].wrapperBlocks[index].offset = .zero
                        dataManager.saveData()
                    }
                    draggedBlockId = nil
                }
        )
        .onLongPressGesture {
            Task{
                enlargedText = block.isFlipped ? block.backText : block.text
                enlargedTextColor = block.isFlipped ? Color.white : Color.primary
                enlargedBackgroundColor = block.isFlipped ? block.color : Color.white
                print(enlargedText)
            }
            showEnlargedText = true
        }
    }
    
    // MARK: - WrappedBlockView
    private func wrappedBlockView(block: WrappedBlock, index: Int, isSelected: Bool) -> some View {
        ZStack {
            Rectangle()
                .fill(block.isFlipped ? block.color : Color.white)
                .shadow(color: .gray.opacity(block.isFlipped ? 0.4 : 0.2), radius: 2, x: 0, y: 1)
            
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange, lineWidth: 3)
                    .opacity(0.8)
            }
            
            HStack(spacing: 0) {
                Rectangle()
                    .fill(block.isFlipped ? Color.white : block.color)
                    .frame(width: 4)
                
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .orange : .gray)
                        .font(.system(size: 14))
                        .padding(.leading, 4)
                }
                
                Text(block.isFlipped ? block.backText : block.text)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(block.isFlipped ? Color.white : .primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(width: 240, height: 90)
        .position(
            x: block.position.x + block.offset.width,
            y: block.position.y + block.offset.height
        )
        .onTapGesture {
            if isSelectionMode {
                if selectedWrappedBlocks.contains(block.id) {
                    selectedWrappedBlocks.remove(block.id)
                } else {
                    selectedWrappedBlocks.insert(block.id)
                }
            } else {
                guard let pageId = selectedPageId,
                      let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }),
                      index < dataManager.pages[pageIndex].wrappedBlocks.count else { return }
                dataManager.pages[pageIndex].wrappedBlocks[index].isFlipped.toggle()
                dataManager.saveData()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if isSelectionMode {
                        applyOffsetToSelectedBlocks(value.translation)
                    } else {
                        guard let pageId = selectedPageId,
                              let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }),
                              index < dataManager.pages[pageIndex].wrappedBlocks.count else { return }
                        dataManager.pages[pageIndex].wrappedBlocks[index].position = value.location
                    }
                    
                    // ドロップターゲットの検出
                    guard let page = currentPage else { return }
                    let dragPosition = value.location
                    if let targetIndex = page.wrapperBlocks.firstIndex(where: { dropAreaForWrapperBlock($0).contains(dragPosition) }) {
                        dropTargetedWrapperIndex = targetIndex
                    } else {
                        dropTargetedWrapperIndex = nil
                    }
                }
                .onEnded { value in
                    let droppedPosition = value.location
                    guard let pageId = selectedPageId,
                          let pageIndex = dataManager.pages.firstIndex(where: { $0.id == pageId }) else { return }
                    
                    var page = dataManager.pages[pageIndex]
                    
                    if isSelectionMode {
                        commitSelectedBlocksPosition()
                    } else {
                        guard index < page.wrappedBlocks.count else { return }
                        
                        // WrapperBlockへのドロップ
                        if let targetIndex = page.wrapperBlocks.firstIndex(where: { dropAreaForWrapperBlock($0).contains(droppedPosition) }) {
                            let movedBlock = page.wrappedBlocks[index]
                            var newBlock = movedBlock
                            newBlock.position = .zero
                            newBlock.offset = .zero
                            page.wrapperBlocks[targetIndex].wrappedBlocks.append(newBlock)
                            page.wrappedBlocks.remove(at: index)
                        } else {
                            // 位置更新 - apply grid snapping
                            let snappedPosition = snapToGrid(value.location)
                            page.wrappedBlocks[index].position = snappedPosition
                            page.wrappedBlocks[index].offset = .zero
                        }
                        dataManager.pages[pageIndex] = page
                        dataManager.saveData()
                    }
                    dropTargetedWrapperIndex = nil
                }
        )
        .onLongPressGesture {
            Task{
                enlargedText = block.isFlipped ? block.backText : block.text
                enlargedTextColor = block.isFlipped ? Color.white : Color.primary
                enlargedBackgroundColor = block.isFlipped ? block.color : Color.white
                print(enlargedText)
                print(enlargedTextColor)
                print(enlargedBackgroundColor)
            }
            showEnlargedText = true
        }
    }
    
    // MARK: - DraggableRowView
    struct DraggableRowView: View {
        let content: WrappedBlock
        let blockIndex: Int
        let wrappedIndex: Int
        @Binding var wrappedBlocks: [WrappedBlock]
        @Binding var contents: [WrappedBlock]
        @GestureState private var dragOffset: CGSize = .zero
        @State private var currentPosition: CGPoint = .zero
        var frameForWrapperBlock: (WrapperBlock) -> CGRect
        let parentBlock: WrapperBlock
        let onMoveUp: () -> Void
        let onMoveDown: () -> Void
        let canMoveUp: Bool
        let canMoveDown: Bool
        let onEnlargeRequested: (String, Color, Color) -> Void
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(content.isFlipped ? Color.white : content.color)
                        .frame(width: 18, height: 18)
                    
                    Text(content.isFlipped ? content.backText : content.text)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(content.isFlipped ? .white : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    VStack(spacing: 2) {
                        Button(action: onMoveUp) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(canMoveUp ? .blue : .gray.opacity(0.5))
                        }
                        .disabled(!canMoveUp)
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                        
                        Button(action: onMoveDown) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(canMoveDown ? .blue : .gray.opacity(0.5))
                        }
                        .disabled(!canMoveDown)
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                    }
                    .frame(width: 36)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(content.isFlipped ? content.color : Color.gray.opacity(0.1))
                )
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            let rowOrigin = CGPoint(x: parentBlock.position.x, y: parentBlock.position.y)
                            let droppedPosition = CGPoint(x: rowOrigin.x + value.translation.width, y: rowOrigin.y + value.translation.height)
                            let frame = frameForWrapperBlock(parentBlock)
                            if !frame.contains(droppedPosition) {
                                if let idx = wrappedBlocks.firstIndex(where: { $0.id == content.id }) {
                                    let removed = wrappedBlocks.remove(at: idx)
                                    var newBlock = removed
                                    newBlock.position = snapToGrid(droppedPosition)
                                    contents.append(newBlock)
                                }
                            }
                        }
                )
                .onTapGesture {
                    var newBlocks = wrappedBlocks
                    if let idx = newBlocks.firstIndex(where: { $0.id == content.id }) {
                        newBlocks[idx].isFlipped.toggle()
                        wrappedBlocks = newBlocks
                    }
                }
                .onLongPressGesture {
                    onEnlargeRequested(
                        content.isFlipped ? content.backText : content.text,
                        content.isFlipped ? Color.white : Color.primary,
                        content.isFlipped ? content.color : Color.white
                    )
                }
            }
        }
    }
    
    // MARK: - GridBackgroundView
    private struct GridBackgroundView: View {
        let gridSize: CGFloat = 30
        let lineColor: Color = .gray.opacity(0.15)
        let lineWidth: CGFloat = 1
        
        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width * 3
                let height = geometry.size.width * 3
                Path { path in
                    stride(from: 0, through: width, by: gridSize).forEach { x in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    stride(from: 0, through: height, by: gridSize).forEach { y in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(lineColor, lineWidth: lineWidth)
            }
        }
    }
}

// MARK: - PageManagerView
struct PageManagerView: View {
    @Binding var isPresented: Bool
    @Binding var selectedPageId: UUID?
    @ObservedObject private var dataManager = DataManager.shared
    @State private var showingAddPage = false
    @State private var newPageName = ""
    @State private var editingPageId: UUID?
    @State private var editingPageName = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.pages, id: \.id) { page in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(page.name)
                                .font(.headline)
                            Text("\(page.wrapperBlocks.count)個のWrapperBlock, \(page.wrappedBlocks.count)個のWrappedBlock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedPageId == page.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                        
                        Button("編集") {
                            editingPageId = page.id
                            editingPageName = page.name
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPageId = page.id
                    }
                }
                .onDelete(perform: deletePages)
            }
            .navigationTitle("ページ管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新規ページ") {
                        showingAddPage = true
                    }
                }
            }
            .alert("ページ名を編集", isPresented: .constant(editingPageId != nil)) {
                TextField("ページ名", text: $editingPageName)
                Button("保存") {
                    if let pageId = editingPageId {
                        dataManager.updatePageName(id: pageId, newName: editingPageName)
                    }
                    editingPageId = nil
                    editingPageName = ""
                }
                Button("キャンセル", role: .cancel) {
                    editingPageId = nil
                    editingPageName = ""
                }
            }
            .alert("新しいページ", isPresented: $showingAddPage) {
                TextField("ページ名", text: $newPageName)
                Button("作成") {
                    if !newPageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        dataManager.addPage(name: newPageName)
                        newPageName = ""
                    }
                }
                Button("キャンセル", role: .cancel) {
                    newPageName = ""
                }
            }
        }
    }
    
    private func deletePages(offsets: IndexSet) {
        for index in offsets {
            let page = dataManager.pages[index]
            dataManager.deletePage(id: page.id)
            if selectedPageId == page.id {
                selectedPageId = dataManager.pages.first?.id
            }
        }
    }
}

#Preview {
    CanvasView()
}
