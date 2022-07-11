//
//  PencilKitView.swift
//  UnityFramework
//
//  Created by blizdliz on 2022/07/03.
//

import SwiftUI

public class PencilKitViewModel: ObservableObject
{
    // 背景画像リセット実行フラグ
    @Published var m_resetBgImage: Bool = false
    // 全削除処理実行フラグ
    @Published var m_eraseAll: Bool = false
    // 保存処理実行フラグ
    @Published var _doSave: Bool = false
    // 保存処理中フラグ
    @Published var m_isSaving: Bool = false
    // 保存処理完了フラグ
    @Published var m_isCompleteSave: Bool = false
    // 保存処理のコールバック
    @Published var m_doSaveCallback: ()->Void = {}
    
    static let shared = PencilKitViewModel()
}

struct PencilKitView: View {
    @Environment(\.dismiss) private var dismiss
    // データモデル
    @StateObject var _pencilKitViewModel = PencilKitViewModel.shared
    // 背景画像ファイルのURL文字列
    @State var m_bgImageFileUrlStr: String = ""
    // 共有用に一時保存したファイルのURL
    @State var m_shareItemURL: URL = URL(string: "test")!
    // 全削除アラート表示フラグ
    @State var m_isShowEraseAllAlert:Bool = false
    // 閉じる直前の保存確認アラート表示フラグ
    @State var m_isSaveAlert:Bool = false
    
    var body: some View {
        NavigationView{
            ZStack{
                Color(uiColor: .black)
                    .ignoresSafeArea()
                PencilKitViewControllerContainer(m_bgImageFileUrlStr: $m_bgImageFileUrlStr,
                                                 m_shareItemURL: $m_shareItemURL)
                .ignoresSafeArea()
                .safeAreaInset(edge: .top) {
                    VStack{
                        HStack(alignment: .top, spacing:10)
                        {
                            // 全削除ボタン
                            Button {
                                print("All Delete")
                                self.m_isShowEraseAllAlert.toggle()
                            } label: {
                                Image(systemName: "trash.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                            .alert(isPresented: $m_isShowEraseAllAlert)
                            {
                                Alert(title: Text("全削除"),
                                        message: Text("描いたものを全て削除します。\nよろしいですか？"),
                                        primaryButton: .cancel(Text("削除しない")),    // キャンセル用
                                        secondaryButton: .destructive(Text("削除する"), action: {  // 破壊的変更用
                                        // 全削除を実行
                                        self._pencilKitViewModel.m_eraseAll.toggle()
                                    })
                                )
                            }
                            Spacer()
                            // 閉じるボタン
                            Button {
                                print("close")
                                self.m_isSaveAlert.toggle()
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                            }
                            .alert(isPresented: $m_isSaveAlert)
                            {
                                Alert(title: Text("画像を保存しますか？"),
                                      message: Text("保存せずに閉じると、描いたものは失われます。"),
                                      primaryButton: .cancel(Text("保存しない"),action: {
                                            // ビューを閉じる
                                            dismiss()
                                        }),    // キャンセル用
                                      secondaryButton: .default(Text("保存する"), action: {  // 破壊的変更用
                                        // 画像の保存を実行
                                        self._pencilKitViewModel._doSave = true
                                        // 以下の処理をコールバックで実行
                                        self._pencilKitViewModel.m_doSaveCallback = {
                                            // Unityにメッセージを送付
                                            PencilKitPlugin.sendToUnity(message: m_shareItemURL.path)
                                            // ビューを閉じる
                                            dismiss()
                                        }
                                    })
                                )
                            }
                        }
                        .padding(10)
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .statusBar(hidden: true)
        }
        .navigationViewStyle(.stack)
    }
}

struct PencilKitView_Previews: PreviewProvider {
    static var previews: some View {
        PencilKitView()
    }
}
