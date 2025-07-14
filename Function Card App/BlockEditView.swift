//
//  BlockEditView.swift
//  Function Card App
//
//  Created by 山口昂大 on 2025/07/14.
//

import SwiftUI

struct BlockEditView: View {
    @State private var editingBlock: BlockManagementView.EditingBlock
    let onSave: (BlockManagementView.EditingBlock) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    init(editingBlock: BlockManagementView.EditingBlock, onSave: @escaping (BlockManagementView.EditingBlock) -> Void) {
        self._editingBlock = State(initialValue: editingBlock)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ブロック情報")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("表面テキスト")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("表面テキスト", text: $editingBlock.text)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("裏面テキスト")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("裏面テキスト", text: $editingBlock.backText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("グループ")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Picker("グループ", selection: $editingBlock.group) {
                            ForEach(BlockGroup.allCases, id: \.self) { group in
                                Text(group.rawValue).tag(group)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // カラープレビュー
                        HStack {
                            Text("カラー:")
                            RoundedRectangle(cornerRadius: 8)
                                .fill(editingBlock.group.color)
                                .frame(width: 40, height: 30)
                            Text(editingBlock.group.colorDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                
//                Section(header: Text("位置")) {
//                    HStack {
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("X座標")
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                            TextField("X座標", value: $editingBlock.position.x, format: .number)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .keyboardType(.numberPad)
//                        }
//                        
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("Y座標")
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                            TextField("Y座標", value: $editingBlock.position.y, format: .number)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .keyboardType(.numberPad)
//                        }
//                    }
//                }
                
                Section(header: Text("プレビュー")) {
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(editingBlock.group.color)
                            .frame(width: 8, height: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(editingBlock.text)
                                .font(.headline)
                            Text(editingBlock.backText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(editingBlock.group.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(editingBlock.group.color.opacity(0.2))
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("ブロック編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    onSave(editingBlock)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(editingBlock.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                         editingBlock.backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}
