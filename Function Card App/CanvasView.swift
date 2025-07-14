//
//  CanvasView.swift
//  Function Card App
//
//  Created by 山口昂大 on 2025/07/12.
//

import SwiftUI

struct CanvasView: View {
    @ObservedObject private var dataManager = DataManager.shared
    
    enum CanvasPage: String, CaseIterable {
        case mechanism = "仕組みページ"
        case appearance = "見た目ページ"
    }
    @State private var selectedPage: CanvasPage = .mechanism
    
    // 選択モード関連
    @State private var isSelectionMode: Bool = false
    @State private var selectedWrapperBlocks: Set<UUID> = []
    @State private var selectedWrappedBlocks: Set<UUID> = []
    
    // ドラッグ中の状態管理
    @State private var isDraggingSelected: Bool = false
    @State private var draggedBlockId: UUID? = nil
    
    @State private var mechanismOffset: CGSize = .zero
    @State private var appearanceOffset: CGSize = .zero
    
    @State private var canvasScale: CGFloat = 1.0
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
    
    @State private var horizontalSliderValue: Double = 0.5
    @State private var verticalSliderValue: Double = 0.5
    
    private let sliderRange: CGFloat = 2000
    
    // DataManagerからデータを取得
    var mechanismBlocks: [WrapperBlock] { dataManager.mechanismBlocks }
    var appearanceBlocks: [WrapperBlock] { dataManager.appearanceBlocks }
    var mechanismContents: [WrappedBlock] { dataManager.mechanismContents }
    var appearanceContents: [WrappedBlock] { dataManager.appearanceContents }
    
    /// 選択モードの切り替え
    private func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedWrapperBlocks.removeAll()
            selectedWrappedBlocks.removeAll()
        }
    }
    
    /// 選択されたブロックをクリア
    private func clearSelection() {
        selectedWrapperBlocks.removeAll()
        selectedWrappedBlocks.removeAll()
    }
    
    /// 選択されたブロックすべてにオフセットを適用（最適化版）
    private func applyOffsetToSelectedBlocks(_ offset: CGSize) {
        // WrapperBlocksにオフセットを適用
        var updatedMechanismBlocks = dataManager.mechanismBlocks
        var updatedAppearanceBlocks = dataManager.appearanceBlocks
        
        if selectedPage == .mechanism {
            for i in updatedMechanismBlocks.indices {
                if selectedWrapperBlocks.contains(updatedMechanismBlocks[i].id) {
                    updatedMechanismBlocks[i].offset = offset
                }
            }
            dataManager.mechanismBlocks = updatedMechanismBlocks
        } else {
            for i in updatedAppearanceBlocks.indices {
                if selectedWrapperBlocks.contains(updatedAppearanceBlocks[i].id) {
                    updatedAppearanceBlocks[i].offset = offset
                }
            }
            dataManager.appearanceBlocks = updatedAppearanceBlocks
        }
        
        // WrappedBlocksにオフセットを適用
        var updatedMechanismContents = dataManager.mechanismContents
        var updatedAppearanceContents = dataManager.appearanceContents
        
        if selectedPage == .mechanism {
            for i in updatedMechanismContents.indices {
                if selectedWrappedBlocks.contains(updatedMechanismContents[i].id) {
                    updatedMechanismContents[i].offset = offset
                }
            }
            dataManager.mechanismContents = updatedMechanismContents
        } else {
            for i in updatedAppearanceContents.indices {
                if selectedWrappedBlocks.contains(updatedAppearanceContents[i].id) {
                    updatedAppearanceContents[i].offset = offset
                }
            }
            dataManager.appearanceContents = updatedAppearanceContents
        }
    }
    
    /// 選択されたブロックすべてのポジションを更新してオフセットをリセット（最適化版）
    private func commitSelectedBlocksPosition() {
        // WrapperBlocksのポジション更新
        var updatedMechanismBlocks = dataManager.mechanismBlocks
        var updatedAppearanceBlocks = dataManager.appearanceBlocks
        
        if selectedPage == .mechanism {
            for i in updatedMechanismBlocks.indices {
                if selectedWrapperBlocks.contains(updatedMechanismBlocks[i].id) {
                    updatedMechanismBlocks[i].position.x += updatedMechanismBlocks[i].offset.width
                    updatedMechanismBlocks[i].position.y += updatedMechanismBlocks[i].offset.height
                    updatedMechanismBlocks[i].offset = .zero
                }
            }
            dataManager.mechanismBlocks = updatedMechanismBlocks
        } else {
            for i in updatedAppearanceBlocks.indices {
                if selectedWrapperBlocks.contains(updatedAppearanceBlocks[i].id) {
                    updatedAppearanceBlocks[i].position.x += updatedAppearanceBlocks[i].offset.width
                    updatedAppearanceBlocks[i].position.y += updatedAppearanceBlocks[i].offset.height
                    updatedAppearanceBlocks[i].offset = .zero
                }
            }
            dataManager.appearanceBlocks = updatedAppearanceBlocks
        }
        
        // WrappedBlocksのポジション更新
        var updatedMechanismContents = dataManager.mechanismContents
        var updatedAppearanceContents = dataManager.appearanceContents
        
        if selectedPage == .mechanism {
            for i in updatedMechanismContents.indices {
                if selectedWrappedBlocks.contains(updatedMechanismContents[i].id) {
                    updatedMechanismContents[i].position.x += updatedMechanismContents[i].offset.width
                    updatedMechanismContents[i].position.y += updatedMechanismContents[i].offset.height
                    updatedMechanismContents[i].offset = .zero
                }
            }
            dataManager.mechanismContents = updatedMechanismContents
        } else {
            for i in updatedAppearanceContents.indices {
                if selectedWrappedBlocks.contains(updatedAppearanceContents[i].id) {
                    updatedAppearanceContents[i].position.x += updatedAppearanceContents[i].offset.width
                    updatedAppearanceContents[i].position.y += updatedAppearanceContents[i].offset.height
                    updatedAppearanceContents[i].offset = .zero
                }
            }
            dataManager.appearanceContents = updatedAppearanceContents
        }
        
        // データを保存
        dataManager.saveData()
    }
    
    /// WrapperBlockのframe（CGRect）を返す
    private func frameForWrapperBlock(_ block: WrapperBlock) -> CGRect {
        let size = CGSize(width: 360, height: 360)
        return CGRect(origin: CGPoint(x: block.position.x, y: block.position.y), size: size)
    }
    
    /// WrapperBlockの実際の描画位置を考慮したドロップエリア
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
    
    private func narrowFrameForWrapperBlock(_ block: WrapperBlock) -> CGRect {
        return dropAreaForWrapperBlock(block)
    }
    
    private func moveWrappedBlock(in blockIndex: Int, from sourceIndex: Int, direction: MoveDirection) {
        var blocks = selectedPage == .mechanism ? mechanismBlocks : appearanceBlocks
        guard blockIndex < blocks.count else { return }
        
        let targetIndex: Int
        switch direction {
        case .up:
            targetIndex = max(0, sourceIndex - 1)
        case .down:
            targetIndex = min(blocks[blockIndex].wrappedBlocks.count - 1, sourceIndex + 1)
        }
        
        if sourceIndex != targetIndex {
            let movedItem = blocks[blockIndex].wrappedBlocks.remove(at: sourceIndex)
            blocks[blockIndex].wrappedBlocks.insert(movedItem, at: targetIndex)
            if selectedPage == .mechanism {
                dataManager.mechanismBlocks = blocks
            } else {
                dataManager.appearanceBlocks = blocks
            }
            dataManager.saveData()
        }
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
    
    private func sliderToOffset(_ value: Double) -> CGFloat {
        return CGFloat((value - 0.5) * 2 * Double(sliderRange))
    }
    
    private func offsetToSlider(_ offset: CGFloat) -> Double {
        return Double(offset) / Double(sliderRange * 2) + 0.5
    }
    
    private func updateSlidersFromOffset() {
        let offset = selectedPage == .mechanism ? mechanismOffset : appearanceOffset
        horizontalSliderValue = offsetToSlider(offset.width)
        verticalSliderValue = offsetToSlider(-offset.height)
        
        horizontalSliderValue = max(0, min(1, horizontalSliderValue))
        verticalSliderValue = max(0, min(1, verticalSliderValue))
    }
    
    enum MoveDirection {
        case up, down
    }
    
    var body: some View {
        NavigationStack{
            VStack {
                // 上部のコントロール
                HStack {
                    Picker("", selection: $selectedPage) {
                        ForEach(CanvasPage.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Spacer()
                    
                    // 管理画面ボタンを追加
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
                
                GeometryReader { geometry in
                    let combinedGesture = DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            if selectedPage == .mechanism {
                                mechanismOffset.width += value.translation.width
                                mechanismOffset.height += value.translation.height
                            } else {
                                appearanceOffset.width += value.translation.width
                                appearanceOffset.height += value.translation.height
                            }
                            updateSlidersFromOffset()
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
                    
                    ZStack {
                        ZStack {
                            GridBackgroundView()
                                .ignoresSafeArea()
                            
                            let blocks = selectedPage == .mechanism ? mechanismBlocks : appearanceBlocks
                            let contents = selectedPage == .mechanism ? mechanismContents : appearanceContents
                            
                            ForEach(0..<blocks.count, id: \.self) { index in
                                wrapperBlockView(
                                    block: blocks[index],
                                    index: index,
                                    isDropTargeted: dropTargetedWrapperIndex == index,
                                    isSelected: selectedWrapperBlocks.contains(blocks[index].id)
                                )
                            }
                            ForEach(0..<contents.count, id: \.self) { index in
                                wrappedBlockView(
                                    block: contents[index],
                                    index: index,
                                    isSelected: selectedWrappedBlocks.contains(contents[index].id)
                                )
                            }
                        }
                        .scaleEffect(canvasScale * gestureScale)
                        .offset(x: (selectedPage == .mechanism ? mechanismOffset.width : appearanceOffset.width) + dragOffset.width,
                                y: (selectedPage == .mechanism ? mechanismOffset.height : appearanceOffset.height) + dragOffset.height)
                        .gesture( combinedGesture)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
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
        .onAppear {
            updateSlidersFromOffset()
        }
    }
    
    private func moveRow(index: Int, from source: IndexSet, to destination: Int) {
        var blocks = selectedPage == .mechanism ? mechanismBlocks : appearanceBlocks
        blocks[index].wrappedBlocks.move(fromOffsets: source, toOffset: destination)
        if selectedPage == .mechanism {
            dataManager.mechanismBlocks = blocks
        } else {
            dataManager.appearanceBlocks = blocks
        }
        dataManager.saveData()
    }
    
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
                                        if selectedPage == .mechanism {
                                            return mechanismBlocks[index].wrappedBlocks
                                        } else {
                                            return appearanceBlocks[index].wrappedBlocks
                                        }
                                    },
                                    set: { newValue in
                                        var blocks = selectedPage == .mechanism ? dataManager.mechanismBlocks : dataManager.appearanceBlocks
                                        blocks[index].wrappedBlocks = newValue
                                        if selectedPage == .mechanism {
                                            dataManager.mechanismBlocks = blocks
                                        } else {
                                            dataManager.appearanceBlocks = blocks
                                        }
                                        dataManager.saveData()
                                    }),
                                contents: Binding(
                                    get: {
                                        if selectedPage == .mechanism {
                                            return mechanismContents
                                        } else {
                                            return appearanceContents
                                        }
                                    },
                                    set: { newValue in
                                        if selectedPage == .mechanism {
                                            dataManager.mechanismContents = newValue
                                        } else {
                                            dataManager.appearanceContents = newValue
                                        }
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
                                    enlargedText = text
                                    enlargedTextColor = textColor
                                    enlargedBackgroundColor = bgColor
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
            y: block.position.y +  block.offset.height
        )
        .onTapGesture {
            if isSelectionMode {
                if selectedWrapperBlocks.contains(block.id) {
                    selectedWrapperBlocks.remove(block.id)
                } else {
                    selectedWrapperBlocks.insert(block.id)
                }
            } else {
                var blocks = selectedPage == .mechanism ? dataManager.mechanismBlocks : dataManager.appearanceBlocks
                blocks[index].isFlipped.toggle()
                if selectedPage == .mechanism {
                    dataManager.mechanismBlocks = blocks
                } else {
                    dataManager.appearanceBlocks = blocks
                }
                dataManager.saveData()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if isSelectionMode {
                        // 選択モード: 選択されたすべてのブロックに同じオフセットを適用
                        applyOffsetToSelectedBlocks(value.translation)
                    } else {
                        // 単体モード: このブロックのみにオフセットを適用
                        var blocks = selectedPage == .mechanism ? dataManager.mechanismBlocks : dataManager.appearanceBlocks
                        blocks[index].offset = value.translation
                        if selectedPage == .mechanism {
                            dataManager.mechanismBlocks = blocks
                        } else {
                            dataManager.appearanceBlocks = blocks
                        }
                    }
                }
                .onEnded { value in
                    if isSelectionMode {
                        // 選択モード: 選択されたすべてのブロックのポジションを更新
                        commitSelectedBlocksPosition()
                    } else {
                        // 単体モード: このブロックのみのポジションを更新
                        var blocks = selectedPage == .mechanism ? dataManager.mechanismBlocks : dataManager.appearanceBlocks
                        blocks[index].position.x += value.translation.width
                        blocks[index].position.y += value.translation.height
                        blocks[index].offset = .zero
                        if selectedPage == .mechanism {
                            dataManager.mechanismBlocks = blocks
                        } else {
                            dataManager.appearanceBlocks = blocks
                        }
                        dataManager.saveData()
                    }
                    draggedBlockId = nil
                }
        )
        .onLongPressGesture {
            enlargedText = block.isFlipped ? block.backText : block.text
            enlargedTextColor = block.isFlipped ? Color.white : Color.primary
            enlargedBackgroundColor = block.isFlipped ? block.color : Color.white
            showEnlargedText = true
        }
    }
    
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
            x: block.position.x  + block.offset.width,
            y: block.position.y  + block.offset.height
        )
        .onTapGesture {
            if isSelectionMode {
                if selectedWrappedBlocks.contains(block.id) {
                    selectedWrappedBlocks.remove(block.id)
                } else {
                    selectedWrappedBlocks.insert(block.id)
                }
            } else {
                var contents = selectedPage == .mechanism ? dataManager.mechanismContents : dataManager.appearanceContents
                contents[index].isFlipped.toggle()
                if selectedPage == .mechanism {
                    dataManager.mechanismContents = contents
                } else {
                    dataManager.appearanceContents = contents
                }
                dataManager.saveData()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if isSelectionMode {
                        // 選択モード: 選択されたすべてのブロックに同じオフセットを適用
                        applyOffsetToSelectedBlocks(value.translation)
                    } else {
                        // 単体モード: このブロックのみにオフセットを適用（直接インデックス指定で高速化）
                        var contents = selectedPage == .mechanism ? dataManager.mechanismContents : dataManager.appearanceContents
                        contents[index].position = value.location
                        if selectedPage == .mechanism {
                            dataManager.mechanismContents = contents
                        } else {
                            dataManager.appearanceContents = contents
                        }
                    }
                    
                    // ドロップターゲットの検出
                    let dragPosition = value.location
                    let blocks = selectedPage == .mechanism ? mechanismBlocks : appearanceBlocks
                    if let targetIndex = blocks.firstIndex(where: { dropAreaForWrapperBlock($0).contains(dragPosition) }) {
                        dropTargetedWrapperIndex = targetIndex
                    } else {
                        dropTargetedWrapperIndex = nil
                    }
                }
                .onEnded { value in
                    let droppedPosition = value.location
                    var contents = selectedPage == .mechanism ? dataManager.mechanismContents : dataManager.appearanceContents
                    var blocks = selectedPage == .mechanism ? dataManager.mechanismBlocks : dataManager.appearanceBlocks
                    
                    if isSelectionMode {
                        // 選択モード: 選択されたすべてのブロックのポジションを更新
                        commitSelectedBlocksPosition()
                    } else {
                        // 単体モード: WrapperBlockにドロップするかまたは位置更新
                        if let targetIndex = blocks.firstIndex(where: { dropAreaForWrapperBlock($0).contains(droppedPosition) }) {
                            // WrapperBlockへのドロップ
                            let movedBlock = contents[index]
                            var newBlock = movedBlock
                            newBlock.position = .zero
                            newBlock.offset = .zero
                            blocks[targetIndex].wrappedBlocks.append(newBlock)
                            contents.remove(at: index)
                            if selectedPage == .mechanism {
                                dataManager.mechanismBlocks = blocks
                                dataManager.mechanismContents = contents
                            } else {
                                dataManager.appearanceBlocks = blocks
                                dataManager.appearanceContents = contents
                            }
                        } else {
                            // 位置更新
                            contents[index].position = value.location
                            contents[index].offset = .zero
                            if selectedPage == .mechanism {
                                dataManager.mechanismContents = contents
                            } else {
                                dataManager.appearanceContents = contents
                            }
                        }
                        dataManager.saveData()
                    }
                    dropTargetedWrapperIndex = nil
                }
        )
        .onLongPressGesture {
            enlargedText = block.isFlipped ? block.backText : block.text
            enlargedTextColor = block.isFlipped ? Color.white : Color.primary
            enlargedBackgroundColor = block.isFlipped ? block.color : Color.white
            showEnlargedText = true
        }
    }
    
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
                                    newBlock.position = droppedPosition
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
    
    private struct GridBackgroundView: View {
        let gridSize: CGFloat = 30
        let lineColor: Color = .gray.opacity(0.15)
        let lineWidth: CGFloat = 1
        
        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width*3
                let height = geometry.size.width*3
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

#Preview {
    CanvasView()
}
