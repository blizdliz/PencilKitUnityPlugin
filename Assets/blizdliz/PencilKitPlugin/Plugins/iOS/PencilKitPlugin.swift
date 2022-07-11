import Foundation
import SwiftUI
import UIKit

public class PencilKitPlugin {
    
    /// PencilKitのビューを表示
    /// - Returns: 処理結果
    public static func showPencilKitView() -> Bool {
        // ログ出力
        print("showPencilKitView")
        
        /// ViewControllerとして取得
        let subVC = UIHostingController(rootView:PencilKitView())
        /// UnityAppControllerを取得する
        let unityAppController:UnityAppController = UIApplication.shared.delegate as! UnityAppController
        /// Unityのビューを取得する
        let unityVC = unityAppController.window.rootViewController
        let unityView = unityVC?.view
        
//        if let sheet = subVC.sheetPresentationController {
//            sheet.detents = [.medium(), .large()]
//            sheet.largestUndimmedDetentIdentifier = .medium
//            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
//            sheet.prefersEdgeAttachedInCompactHeight = true
//            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
//        }
        /// モーダルスタイルでビューを表示する
        subVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        unityVC!.present(subVC, animated: true, completion: nil)
        
        // 戻り値を返す
        return true
    }

    /// UnityへSendMessageを実行する
    public static func sendToUnity(message:String) {
        let objectName = "PencilKitPlugin" as NSString
        let scriptName = "OnCloseCallback" as NSString
        let message = message as NSString
        UnityFramework.getInstance()
            .sendMessageToGO(withName: objectName.utf8String,
                             functionName: scriptName.utf8String,
                             message: message.utf8String)
    }
}

// `@_cdecl("[メソッド名]")`を使うことでCの関数として定義することが可能

// NOTE: この関数が実際にUnity(C#)から呼び出される
@_cdecl("showPencilKitView")
public func showPencilKitView() -> Bool {
    // ↑で実装している`PencilKitPlugin.showPencilKitView`を呼び出すだけ。
    // NOTE: クラスメソッド(静的関数)として実装しているので、クラスをインスタンス化せずに直接呼び出せる
    return PencilKitPlugin.showPencilKitView()
}
