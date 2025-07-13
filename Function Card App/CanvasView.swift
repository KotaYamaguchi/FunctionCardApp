//
//  CanvasView.swift
//  Function Card App
//
//  Created by 山口昂大 on 2025/07/12.
//

import SwiftUI

struct CanvasView: View {
    enum CanvasPage: String, CaseIterable {
        case mechanism = "仕組みページ"
        case appearance = "見た目ページ"
    }
    @State private var selectedPage: CanvasPage = .mechanism
    
    // ページ別データ管理
    @State private var mechanismBlocks: [WrapperBlock] = [
        WrapperBlock(
            id: UUID(),
            position: CGPoint(x: 180, y: 180), // グリッドに合わせて調整
            text: "ブロックA",
            backText: "ブロックA裏",
            color: .red,
            isFlipped: false,
            group: .function,
            wrappedBlocks: [
                WrappedBlock(id: UUID(), position: .zero, text: "A-1", backText: "A-1裏", color: .orange, isFlipped: false, group: .function),
                WrappedBlock(id: UUID(), position: .zero, text: "A-2", backText: "A-2裏", color: .yellow, isFlipped: false, group: .function)
            ]
        ),
        WrapperBlock(
            id: UUID(),
            position: CGPoint(x: 570, y: 180), // グリッドに合わせて調整
            text: "ブロックB",
            backText: "ブロックB裏",
            color: .blue,
            isFlipped: false,
            group: .component,
            wrappedBlocks: [
                WrappedBlock(id: UUID(), position: .zero, text: "B-1", backText: "B-1裏", color: .cyan, isFlipped: false, group: .component),
                WrappedBlock(id: UUID(), position: .zero, text: "B-2", backText: "B-2裏", color: .green, isFlipped: false, group: .component)
            ]
        ),
        WrapperBlock(
            id: UUID(),
            position: CGPoint(x: 180, y: 120), // グリッドに合わせて調整
            text: "ブロックC",
            backText: "ブロックC裏",
            color: .purple,
            isFlipped: false,
            group: .button,
            wrappedBlocks: [
                WrappedBlock(id: UUID(), position: .zero, text: "C-1", backText: "C-1裏", color: .pink, isFlipped: false, group: .button),
                WrappedBlock(id: UUID(), position: .zero, text: "C-2", backText: "C-2裏", color: .mint, isFlipped: false, group: .button)
            ]
        )
    ]
    @State private var appearanceBlocks: [WrapperBlock] = []
    
    @State private var mechanismContents: [WrappedBlock] = [
        WrappedBlock(
            id: UUID(),
            position: CGPoint(x: 120, y: 120),
            text: "コンテンツ1",
            backText: "裏1",
            color: .pink,
            isFlipped: false,
            group: .other
        ),
        WrappedBlock(
            id: UUID(),
            position: CGPoint(x: 300, y: 150),
            text: "コンテンツ2",
            backText: "裏2",
            color: .yellow,
            isFlipped: false,
            group: .stack
        ),
        WrappedBlock(
            id: UUID(),
            position: CGPoint(x: 480, y: 240),
            text: "コンテンツ3",
            backText: "裏3",
            color: .green,
            isFlipped: false,
            group: .button
        ),
        WrappedBlock(
            id: UUID(),
            position: CGPoint(x: 180, y: 390),
            text: "コンテンツ4",
            backText: "裏4",
            color: .blue,
            isFlipped: false,
            group: .component
        ),
        WrappedBlock(
            id: UUID(),
            position: CGPoint(x: 390, y: 480),
            text: "コンテンツ5",
            backText: "裏5",
            color: .orange,
            isFlipped: false,
            group: .function
        )
    ]
    @State private var appearanceContents: [WrappedBlock] = []
    
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
    
    // グリッドスナップ用の設定
    private let gridSize: CGFloat = 30
    
    /// グリッドスナップ関数（左上基準）
    private func snapToGridLeftTop(_ point: CGPoint) -> CGPoint {
        let snappedX = round(point.x / gridSize) * gridSize
        let snappedY = round(point.y / gridSize) * gridSize
        return CGPoint(x: snappedX, y: snappedY)
    }
    
    /// WrapperBlockのframe（CGRect）を返す - サイズを360x360に変更
    private func frameForWrapperBlock(_ block: WrapperBlock) -> CGRect {
        let size = CGSize(width: 360, height: 360) // 30の12倍
        return CGRect(origin: CGPoint(x: block.position.x, y: block.position.y), size: size)
    }
    
    /// WrapperBlockの実際の描画位置を考慮したドロップエリア（修正版）
    private func dropAreaForWrapperBlock(_ block: WrapperBlock) -> CGRect {
        let headerHeight: CGFloat = 60
        let blockRowHeight: CGFloat = 30
        let bottomSpace: CGFloat = 30
        let dynamicHeight = headerHeight + CGFloat(block.wrappedBlocks.count) * blockRowHeight + bottomSpace
        let adjustedHeight = ceil(dynamicHeight / 30) * 30
        
        let margin: CGFloat = 20
        
        // 実際の描画位置（中心座標）から左上座標を算出してから範囲を計算
        let centerX = block.position.x + 180 // 左上基準 + 幅の半分
        let centerY = block.position.y + adjustedHeight / 2 // 左上基準 + 高さの半分
        
        let actualLeftTop = CGPoint(
            x: centerX - 180, // 中心座標 - 幅の半分
            y: centerY - adjustedHeight / 2 // 中心座標 - 高さの半分
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
                mechanismBlocks = blocks
            } else {
                appearanceBlocks = blocks
            }
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
        VStack {
            Picker("", selection: $selectedPage) {
                ForEach(CanvasPage.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
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
                            wrapperBlockView(block: blocks[index], index: index, isDropTargeted: dropTargetedWrapperIndex == index)
                        }
                        ForEach(0..<contents.count, id: \.self) { index in
                            wrappedBlockView(block: contents[index], index: index)
                        }
                    }
                    .scaleEffect(canvasScale * gestureScale)
                    .offset(x: (selectedPage == .mechanism ? mechanismOffset.width : appearanceOffset.width) + dragOffset.width,
                            y: (selectedPage == .mechanism ? mechanismOffset.height : appearanceOffset.height) + dragOffset.height)
                    .gesture(combinedGesture)
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
                    }
                    .padding(.top, 20)
                }
            }
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
        if selectedPage == .mechanism {
            mechanismBlocks[index].wrappedBlocks.move(fromOffsets: source, toOffset: destination)
        } else {
            appearanceBlocks[index].wrappedBlocks.move(fromOffsets: source, toOffset: destination)
        }
    }
    
    private func wrapperBlockView(block: WrapperBlock, index: Int, isDropTargeted: Bool) -> some View {
        let headerHeight: CGFloat = 60 // 30の2倍
        let blockRowHeight: CGFloat = 30 // 30の1倍
        let bottomSpace: CGFloat = 30 // 30の1倍
        let dynamicHeight = headerHeight + CGFloat(block.wrappedBlocks.count) * blockRowHeight + bottomSpace
        // 動的な高さも30の倍数になるよう調整
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
            
            VStack(spacing: 0) {
                Rectangle()
                    .fill(block.isFlipped ? Color.white : block.color.opacity(0.8))
                    .frame(height: 60) // 30の2倍
                    .overlay(
                        Text(block.isFlipped ? block.backText : block.text)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(block.isFlipped ? block.color : .white)
                            .lineLimit(1)
                            .truncationMode(.tail)
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
                                        if selectedPage == .mechanism {
                                            mechanismBlocks[index].wrappedBlocks = newValue
                                        } else {
                                            appearanceBlocks[index].wrappedBlocks = newValue
                                        }
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
                                            mechanismContents = newValue
                                        } else {
                                            appearanceContents = newValue
                                        }
                                    }),
                                frameForWrapperBlock: frameForWrapperBlock,
                                parentBlock: block,
                                snapToGrid: snapToGridLeftTop,
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
        .frame(width: 360, height: adjustedHeight) // 360は30の12倍
        .position(
            x: block.position.x + 180, // 左上基準 + 幅の半分
            y: block.position.y + adjustedHeight / 2 // 左上基準 + 高さの半分
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    // ドラッグ中は中心位置から左上位置を逆算
                    let leftTopPosition = CGPoint(
                        x: value.location.x - 180, // 中心位置 - 幅の半分
                        y: value.location.y - adjustedHeight / 2 // 中心位置 - 高さの半分
                    )
                    if selectedPage == .mechanism {
                        mechanismBlocks[index].position = leftTopPosition
                    } else {
                        appearanceBlocks[index].position = leftTopPosition
                    }
                }
                .onEnded { value in
                    // 左上をグリッドにスナップ
                    let leftTopPosition = CGPoint(
                        x: value.location.x - 180, // 中心位置 - 幅の半分
                        y: value.location.y - adjustedHeight / 2 // 中心位置 - 高さの半分
                    )
                    let snappedPosition = snapToGridLeftTop(leftTopPosition)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if selectedPage == .mechanism {
                            mechanismBlocks[index].position = snappedPosition
                        } else {
                            appearanceBlocks[index].position = snappedPosition
                        }
                    }
                }
        )
        .onTapGesture {
            if selectedPage == .mechanism {
                mechanismBlocks[index].isFlipped.toggle()
            } else {
                appearanceBlocks[index].isFlipped.toggle()
            }
        }
        .onLongPressGesture {
            enlargedText = block.isFlipped ? block.backText : block.text
            enlargedTextColor = block.isFlipped ? Color.white : Color.primary
            enlargedBackgroundColor = block.isFlipped ? block.color : Color.white
            showEnlargedText = true
        }
    }
    
    private func wrappedBlockView(block: WrappedBlock, index: Int) -> some View {
        ZStack {
            Rectangle()
                .fill(block.isFlipped ? block.color : Color.white)
                .shadow(color: .gray.opacity(block.isFlipped ? 0.4 : 0.2), radius: 2, x: 0, y: 1)
            
            HStack(spacing: 0) {
                Rectangle()
                    .fill(block.isFlipped ? Color.white : block.color)
                    .frame(width: 4)
                
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
        .frame(width: 240, height: 90) // 240は30の8倍、90は30の3倍
        .position(
            x: block.position.x + 120, // 左上基準 + 幅の半分
            y: block.position.y + 45 // 左上基準 + 高さの半分
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    // ドラッグ中は中心位置から左上位置を逆算
                    let leftTopPosition = CGPoint(
                        x: value.location.x - 120, // 中心位置 - 幅の半分
                        y: value.location.y - 45 // 中心位置 - 高さの半分
                    )
                    if selectedPage == .mechanism {
                        mechanismContents[index].position = leftTopPosition
                    } else {
                        appearanceContents[index].position = leftTopPosition
                    }
                    
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
                    var contents = selectedPage == .mechanism ? mechanismContents : appearanceContents
                    var blocks = selectedPage == .mechanism ? mechanismBlocks : appearanceBlocks
                    if let targetIndex = blocks.firstIndex(where: { dropAreaForWrapperBlock($0).contains(droppedPosition) }) {
                        let movedBlock = contents[index]
                        var newBlock = movedBlock
                        newBlock.position = .zero
                        blocks[targetIndex].wrappedBlocks.append(newBlock)
                        contents.remove(at: index)
                        if selectedPage == .mechanism {
                            mechanismBlocks = blocks
                            mechanismContents = contents
                        } else {
                            appearanceBlocks = blocks
                            appearanceContents = contents
                        }
                    } else {
                        // 左上をグリッドにスナップ
                        let leftTopPosition = CGPoint(
                            x: value.location.x - 120, // 中心位置 - 幅の半分
                            y: value.location.y - 45 // 中心位置 - 高さの半分
                        )
                        let snappedPosition = snapToGridLeftTop(leftTopPosition)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedPage == .mechanism {
                                mechanismContents[index].position = snappedPosition
                            } else {
                                appearanceContents[index].position = snappedPosition
                            }
                        }
                    }
                    dropTargetedWrapperIndex = nil
                }
        )
        .onTapGesture {
            if selectedPage == .mechanism {
                mechanismContents[index].isFlipped.toggle()
            } else {
                appearanceContents[index].isFlipped.toggle()
            }
        }
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
        let snapToGrid: (CGPoint) -> CGPoint // グリッドスナップ関数を追加
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
                                    // グリッドスナップ機能を追加
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
    
    private struct GridBackgroundView: View {
        let gridSize: CGFloat = 30
        let lineColor: Color = .gray.opacity(0.15)
        let lineWidth: CGFloat = 1

        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width*3
                let height = geometry.size.height*3
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

enum BlockGroup: String, CaseIterable, Codable {
    case function = "関数"
    case component = "コンポーネント"
    case button = "ボタン"
    case stack = "Stack"
    case other = "その他"
}

struct WrapperBlock:Identifiable{
    let id: UUID
    var position: CGPoint
    var text: String
    var backText: String
    var color: Color
    var isFlipped: Bool
    var group: BlockGroup
    var wrappedBlocks:[WrappedBlock]
}

struct WrappedBlock: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var text: String
    var backText: String
    var color: Color
    var isFlipped: Bool
    var group: BlockGroup
    
    static func == (lhs: WrappedBlock, rhs: WrappedBlock) -> Bool {
        lhs.id == rhs.id &&
        lhs.position == rhs.position &&
        lhs.text == rhs.text &&
        lhs.backText == rhs.backText &&
        lhs.color == rhs.color &&
        lhs.isFlipped == rhs.isFlipped &&
        lhs.group == rhs.group
    }
}
