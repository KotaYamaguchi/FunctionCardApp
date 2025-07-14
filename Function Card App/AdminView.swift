//
//  AdminView.swift
//  Function Card App
//
//  Created by 山口昂大 on 2025/07/14.
//

import SwiftUI

struct AdminView: View {
    @ObservedObject private var dataManager = DataManager.shared
    
    @State private var selectedPage: CanvasView.CanvasPage = .mechanism
    @State private var selectedBlockType: BlockType = .wrapper
    @State private var selectedMode: AddMode = .single
    @State private var batchInputFormat: BatchInputFormat = .pipeDelimited
    
    // WrapperBlock用の入力フィールド
    @State private var wrapperText: String = ""
    @State private var wrapperBackText: String = ""
    @State private var wrapperGroup: BlockGroup = .function
    @State private var wrapperPositionX: String = "100"
    @State private var wrapperPositionY: String = "100"
    
    // WrappedBlock用の入力フィールド
    @State private var wrappedText: String = ""
    @State private var wrappedBackText: String = ""
    @State private var wrappedGroup: BlockGroup = .function
    @State private var wrappedPositionX: String = "100"
    @State private var wrappedPositionY: String = "100"
    
    // バッチ追加用フィールド
    @State private var batchData: String = ""
    @State private var batchPositionX: String = "100"
    @State private var batchPositionY: String = "100"
    @State private var batchSpacing: String = "200"
    @State private var batchGroup: BlockGroup = .function
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum BlockType: String, CaseIterable {
        case wrapper = "WrapperBlock"
        case wrapped = "WrappedBlock"
    }
    
    enum AddMode: String, CaseIterable {
        case single = "単体追加"
        case batch = "まとめて追加"
    }
    
    enum BatchInputFormat: String, CaseIterable {
        case pipeDelimited = "パイプ区切り（表|裏）"
        case commaDelimited = "カンマ区切り（表,裏,グループ）"
        
        var description: String {
            switch self {
            case .pipeDelimited:
                return "表面|裏面"
            case .commaDelimited:
                return "表面,裏面,グループ"
            }
        }
        
        var example: String {
            switch self {
            case .pipeDelimited:
                return "ブロック1|ブロック1裏"
            case .commaDelimited:
                return "ブロック1,ブロック1裏,関数"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // ページ選択
            VStack(alignment: .leading, spacing: 10) {
                Text("対象ページ")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("ページ選択", selection: $selectedPage) {
                    ForEach(CanvasView.CanvasPage.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            // ブロックタイプ選択
            VStack(alignment: .leading, spacing: 10) {
                Text("ブロックタイプ")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("ブロックタイプ選択", selection: $selectedBlockType) {
                    ForEach(BlockType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            // 追加モード選択
            VStack(alignment: .leading, spacing: 10) {
                Text("追加モード")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("追加モード選択", selection: $selectedMode) {
                    ForEach(AddMode.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 20) {
                    if selectedMode == .single {
                        if selectedBlockType == .wrapper {
                            wrapperBlockForm
                        } else {
                            wrappedBlockForm
                        }
                        addButton
                    } else {
                        batchInputFormatSelector
                        batchAddForm
                        batchAddButton
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("ブロック管理")
        .navigationBarTitleDisplayMode(.large)
        .alert("結果", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - バッチ入力形式選択
    private var batchInputFormatSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("入力形式")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("入力形式選択", selection: $batchInputFormat) {
                ForEach(BatchInputFormat.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
    }
    
    // MARK: - バッチ追加フォーム
    private var batchAddForm: some View {
        VStack(spacing: 16) {
            Text("まとめて\(selectedBlockType.rawValue)作成")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(selectedBlockType == .wrapper ? .blue : .green)
            
            VStack(alignment: .leading, spacing: 12) {
                // データ入力エリア
                VStack(alignment: .leading, spacing: 4) {
                    Text("ブロックデータ（1行に1つ、\(batchInputFormat.description)の形式）")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("例: \(batchInputFormat.example)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if batchInputFormat == .commaDelimited {
                        Text("利用可能なグループ: \(BlockGroup.allCases.map { $0.rawValue }.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.vertical, 2)
                    }
                    
                    TextEditor(text: $batchData)
                        .font(.system(size: 14))
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                // 共通設定（パイプ区切りの場合のみ表示）
                if batchInputFormat == .pipeDelimited {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("共通設定")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        // グループ選択とカラープレビュー
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("グループ:")
                                    .frame(width: 80, alignment: .leading)
                                Picker("", selection: $batchGroup) {
                                    ForEach(BlockGroup.allCases, id: \.self) { group in
                                        Text(group.rawValue).tag(group)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                            }
                            
                            // カラープレビュー
                            HStack {
                                Text("カラー:")
                                    .frame(width: 80, alignment: .leading)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(batchGroup.color)
                                    .frame(width: 40, height: 30)
                                Text(batchGroup.colorDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                }
                
                // 配置設定
                VStack(alignment: .leading, spacing: 8) {
                    Text("配置設定")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("開始X座標")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("100", text: $batchPositionX)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("開始Y座標")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("100", text: $batchPositionY)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("間隔")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("200", text: $batchSpacing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                    
                    Text("※ブロックは横方向に指定間隔で配置されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - バッチ追加ボタン
    private var batchAddButton: some View {
        VStack(spacing: 12) {
            Button(action: batchAddBlocks) {
                HStack {
                    Image(systemName: "plus.rectangle.on.rectangle")
                        .font(.title2)
                    Text("まとめて追加")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedBlockType == .wrapper ? Color.blue : Color.green)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // プレビュー情報
            let previewCount = batchData.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .count
            
            if previewCount > 0 {
                let groupText = batchInputFormat == .pipeDelimited ?
                    "（\(batchGroup.colorDescription)）" :
                    "（混合グループ）"
                Text("\(previewCount)個のブロックが追加されます\(groupText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                    )
            }
        }
    }
    
    // MARK: - WrapperBlock入力フォーム
    private var wrapperBlockForm: some View {
        VStack(spacing: 16) {
            Text("WrapperBlock作成")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 12) {
                // テキスト入力
                VStack(alignment: .leading, spacing: 4) {
                    Text("表面テキスト")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("例: 新しいブロック", text: $wrapperText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("裏面テキスト")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("例: 新しいブロック裏", text: $wrapperBackText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // グループ選択とカラープレビュー
                VStack(alignment: .leading, spacing: 8) {
                    Text("グループ")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("グループ選択", selection: $wrapperGroup) {
                        ForEach(BlockGroup.allCases, id: \.self) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(height: 40)
                    
                    // カラープレビュー
                    HStack {
                        Text("カラー:")
                        RoundedRectangle(cornerRadius: 8)
                            .fill(wrapperGroup.color)
                            .frame(width: 40, height: 30)
                        Text(wrapperGroup.colorDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                // 位置設定
                VStack(alignment: .leading, spacing: 8) {
                    Text("初期位置")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("X座標")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("100", text: $wrapperPositionX)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Y座標")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("100", text: $wrapperPositionY)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - WrappedBlock入力フォーム
    private var wrappedBlockForm: some View {
        VStack(spacing: 16) {
            Text("WrappedBlock作成")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 12) {
                // テキスト入力
                VStack(alignment: .leading, spacing: 4) {
                    Text("表面テキスト")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("例: 新しいコンテンツ", text: $wrappedText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("裏面テキスト")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("例: 新しいコンテンツ裏", text: $wrappedBackText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // グループ選択とカラープレビュー
                VStack(alignment: .leading, spacing: 8) {
                    Text("グループ")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("グループ選択", selection: $wrappedGroup) {
                        ForEach(BlockGroup.allCases, id: \.self) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(height: 40)
                    
                    // カラープレビュー
                    HStack {
                        Text("カラー:")
                        RoundedRectangle(cornerRadius: 8)
                            .fill(wrappedGroup.color)
                            .frame(width: 40, height: 30)
                        Text(wrappedGroup.colorDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                // 位置設定
                VStack(alignment: .leading, spacing: 8) {
                    Text("初期位置")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("X座標")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("100", text: $wrappedPositionX)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Y座標")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("100", text: $wrappedPositionY)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - 追加ボタン
    private var addButton: some View {
        Button(action: addBlock) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("ブロックを追加")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedBlockType == .wrapper ? Color.blue : Color.green)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - グループ文字列をBlockGroupに変換
    private func parseBlockGroup(from text: String) -> BlockGroup {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return BlockGroup.allCases.first { $0.rawValue == trimmedText } ?? .other
    }
    
    // MARK: - バッチ追加処理
    private func batchAddBlocks() {
        // 入力検証
        guard !batchData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "ブロックデータを入力してください")
            return
        }
        
        guard let startX = Double(batchPositionX),
              let startY = Double(batchPositionY),
              let spacing = Double(batchSpacing) else {
            showAlert(message: "正しい座標と間隔を入力してください")
            return
        }
        
        // データをパース
        let lines = batchData.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            showAlert(message: "有効なデータが見つかりません")
            return
        }
        
        var addedCount = 0
        var errorCount = 0
        
        for (index, line) in lines.enumerated() {
            let components: [String]
            let frontText: String
            let backText: String
            let blockGroup: BlockGroup
            
            if batchInputFormat == .pipeDelimited {
                // パイプ区切り形式の処理
                components = line.components(separatedBy: "|")
                guard components.count >= 2 else {
                    errorCount += 1
                    continue
                }
                
                frontText = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                backText = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                blockGroup = batchGroup // 共通設定を使用
            } else {
                // カンマ区切り形式の処理
                components = line.components(separatedBy: ",")
                guard components.count >= 3 else {
                    errorCount += 1
                    continue
                }
                
                frontText = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                backText = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                blockGroup = parseBlockGroup(from: components[2])
            }
            
            guard !frontText.isEmpty && !backText.isEmpty else {
                errorCount += 1
                continue
            }
            
            let position = CGPoint(
                x: startX + Double(index) * spacing,
                y: startY
            )
            
            if selectedBlockType == .wrapper {
                let newBlock = WrapperBlock.create(
                    position: position,
                    text: frontText,
                    backText: backText,
                    group: blockGroup
                )
                
                dataManager.addWrapperBlock(newBlock, to: selectedPage)
            } else {
                let newBlock = WrappedBlock.create(
                    position: position,
                    text: frontText,
                    backText: backText,
                    group: blockGroup
                )
                
                dataManager.addWrappedBlock(newBlock, to: selectedPage)
            }
            
            addedCount += 1
        }
        
        // 結果表示
        if errorCount > 0 {
            showAlert(message: "\(addedCount)個のブロックを追加しました\n\(errorCount)行でエラーが発生しました")
        } else {
            showAlert(message: "\(addedCount)個の\(selectedBlockType.rawValue)を\(selectedPage.rawValue)に追加しました")
        }
        
        // フォームをクリア
        clearBatchForm()
    }
    
    // MARK: - ブロック追加処理
    private func addBlock() {
        if selectedBlockType == .wrapper {
            addWrapperBlock()
        } else {
            addWrappedBlock()
        }
    }
    
    private func addWrapperBlock() {
        // 入力検証
        guard !wrapperText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "表面テキストを入力してください")
            return
        }
        
        guard !wrapperBackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "裏面テキストを入力してください")
            return
        }
        
        guard let x = Double(wrapperPositionX), let y = Double(wrapperPositionY) else {
            showAlert(message: "正しい座標を入力してください")
            return
        }
        
        // 新しいWrapperBlockを作成
        let newBlock = WrapperBlock.create(
            position: CGPoint(x: x, y: y),
            text: wrapperText.trimmingCharacters(in: .whitespacesAndNewlines),
            backText: wrapperBackText.trimmingCharacters(in: .whitespacesAndNewlines),
            group: wrapperGroup
        )
        
        // DataManagerを使用してブロックを追加
        dataManager.addWrapperBlock(newBlock, to: selectedPage)
        
        // フォームをクリア
        clearWrapperForm()
        
        showAlert(message: "WrapperBlockを\(selectedPage.rawValue)に追加しました")
    }
    
    private func addWrappedBlock() {
        // 入力検証
        guard !wrappedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "表面テキストを入力してください")
            return
        }
        
        guard !wrappedBackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "裏面テキストを入力してください")
            return
        }
        
        guard let x = Double(wrappedPositionX), let y = Double(wrappedPositionY) else {
            showAlert(message: "正しい座標を入力してください")
            return
        }
        
        // 新しいWrappedBlockを作成
        let newBlock = WrappedBlock.create(
            position: CGPoint(x: x, y: y),
            text: wrappedText.trimmingCharacters(in: .whitespacesAndNewlines),
            backText: wrappedBackText.trimmingCharacters(in: .whitespacesAndNewlines),
            group: wrappedGroup
        )
        
        // DataManagerを使用してブロックを追加
        dataManager.addWrappedBlock(newBlock, to: selectedPage)
        
        // フォームをクリア
        clearWrappedForm()
        
        showAlert(message: "WrappedBlockを\(selectedPage.rawValue)に追加しました")
    }
    
    // MARK: - ヘルパー関数
    private func clearWrapperForm() {
        wrapperText = ""
        wrapperBackText = ""
        wrapperGroup = .function
        wrapperPositionX = "100"
        wrapperPositionY = "100"
    }
    
    private func clearWrappedForm() {
        wrappedText = ""
        wrappedBackText = ""
        wrappedGroup = .function
        wrappedPositionX = "100"
        wrappedPositionY = "100"
    }
    
    private func clearBatchForm() {
        batchData = ""
        batchPositionX = "100"
        batchPositionY = "100"
        batchSpacing = "200"
        batchGroup = .function
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    NavigationView {
        AdminView()
    }
}
