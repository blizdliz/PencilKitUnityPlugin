//
//  PencilKitViewControllerContainer.swift
//
//  Created by blizdliz on 2022/05/12.
//

import UIKit
import SwiftUI
import PencilKit
import PDFKit

// PencilKitを使ったお絵描き機能のビュー
// 画面回転には未対応です！！
struct PencilKitViewControllerContainer: UIViewControllerRepresentable {
    
    @ObservedObject var _pencilKitViewModel = PencilKitViewModel.shared
    @Binding var m_bgImageFileUrlStr: String
    @Binding var m_shareItemURL: URL
    
    var _pencilKitViewController:PencilKitViewControllerCoordinator?
    
    // MARK: - UIViewControllerRepresentable
    func makeUIViewController(context: Context) -> PencilKitViewControllerCoordinator {
        let pencilKitViewController = PencilKitViewControllerCoordinator(self)
        return pencilKitViewController
    }
    
    func updateUIViewController(_ uiViewController: PencilKitViewControllerCoordinator, context: Context) {
        print("\(type(of: self)) \(#function)")
        // 画像保存処理を実行
        if self._pencilKitViewModel._doSave
        {
            self._pencilKitViewModel._doSave = false
            uiViewController.saveCurrentPage()
        }
        // 背景画像を変更する
        if self.m_bgImageFileUrlStr.count > 0
        {
            uiViewController.loadImage(urlStr: self.m_bgImageFileUrlStr)
            self.m_bgImageFileUrlStr = ""
        }
        // 背景画像をリセットする
        if self._pencilKitViewModel.m_resetBgImage
        {
            self._pencilKitViewModel.m_resetBgImage = false
            uiViewController.ResetImageView(image: uiViewController.getDefaultImage())
        }
        // 書いたものを全削除する
        if self._pencilKitViewModel.m_eraseAll
        {
            self._pencilKitViewModel.m_eraseAll = false
            uiViewController.eraseAll()
        }
    }
    
    func makeCoordinator() -> PencilKitViewControllerCoordinator {
        return Coordinator(self)
    }
}

class PencilKitViewControllerCoordinator: UIViewController, PKCanvasViewDelegate {
    
    @State private var m_fileOperator = FileOperator()
    
    private lazy var canvasView: PKCanvasView = setupCanvasView()
    private lazy var imageView: UIImageView = setupImageView()
    // 領域外を隠すビュー
    private var _overlayView_1:UIView?
    private var _overlayView_2:UIView?
    // 領域外を隠すビューの位置、サイズ
    private var _overlayView_1_PosX:CGFloat = 0
    private var _overlayView_2_PosX:CGFloat = 0
    private var _overlayView_1_PosY:CGFloat = 0
    private var _overlayView_2_PosY:CGFloat = 0
    private var _overlayViewSizeX:CGFloat = 0
    private var _overlayViewSizeY:CGFloat = 0
    
    let _toolPicker = PKToolPicker()
    // 親のビュー
    var _parent: PencilKitViewControllerContainer
    
    // MARK: - Init
    init(_ parentContainer: PencilKitViewControllerContainer)
    {
        self._parent = parentContainer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewControllerDelegate
    override func viewDidLoad() {
        // Viewの背景色を指定
        self.view.backgroundColor = .black//UIColor(named: "Background_Draw")

        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // 下地となる画像をセットしたimageViewをViewに追加
        self.canvasView.addSubview(self.imageView)
//        // imageViewを後ろのレイヤーに移動
        self.canvasView.sendSubviewToBack(self.imageView)
        self.view.addSubview(self.canvasView)
        
        // 領域外を隠すビューを追加する
        self._overlayView_1 = UIView(frame: CGRect(x: _overlayView_1_PosX, y: _overlayView_1_PosY, width: _overlayViewSizeX, height: _overlayViewSizeY))
        self._overlayView_1!.backgroundColor = .black//UIColor(named: "Background_Draw")
        self.canvasView.addSubview(_overlayView_1!)
        // 領域外を隠すビューを追加する
        self._overlayView_2 = UIView(frame: CGRect(x: _overlayView_2_PosX, y: _overlayView_2_PosY, width: _overlayViewSizeX, height: _overlayViewSizeY))
        self._overlayView_2!.backgroundColor = .black//UIColor(named: "Background_Draw")
        self.canvasView.addSubview(_overlayView_2!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewLayout(viewWidth: self.view.frame.width, viewHeight: self.view.frame.height)
    }
    
    // デバイスの向きが変化した際に呼ばれる処理
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
//            print("viewWillTransition")
//            print(size)
        updateViewLayout(viewWidth: size.width, viewHeight: size.height)
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView == self.canvasView {
            self.imageView.frame.size = CGSize(width: self.view.frame.width * scrollView.zoomScale, height: self.view.frame.height * scrollView.zoomScale)
            self.imageView.center = CGPoint(x: scrollView.contentSize.width / 2, y: scrollView.contentSize.height / 2)
            
            self._overlayView_1!.frame.size = CGSize(width: (_overlayViewSizeX*2) * scrollView.zoomScale, height: (_overlayViewSizeY*2) * scrollView.zoomScale)
            self._overlayView_1!.center = CGPoint(x: 0, y: 0)
            
            self._overlayView_2!.frame.size = CGSize(width: (_overlayViewSizeX*2) * scrollView.zoomScale, height: (_overlayViewSizeY*2) * scrollView.zoomScale)
            self._overlayView_2!.center = CGPoint(x: scrollView.contentSize.width, y: scrollView.contentSize.height)
        }
    }
    
    // MARK: - PKCanvasViewDelegate
    // お絵かき描画を開始した時に呼ばれる(指がcanvasViewに触れた時)
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        print("canvasViewDidBeginUsingTool")
    }
    // お絵かき描画を終了した時に呼ばれる(指がcanvasViewから離れた時)
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        print("canvasViewDrawingDidChange")
    }
    
    // MARK: - PKCanvasView
    private func setupCanvasView() -> PKCanvasView {
        let canvasView: PKCanvasView = PKCanvasView(frame: self.view.frame)
        canvasView.delegate = self
        canvasView.maximumZoomScale = 5.0
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        canvasView.contentOffset = CGPoint.zero
        canvasView.contentSize = self.view.frame.size
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 30)
        // PKToolPicker: ドラッグして移動できるツールパレット (ペンや色などを選択できるツール)
        _toolPicker.addObserver(canvasView)
        _toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }
    
    // 全削除を実行する
    public func eraseAll()
    {
        canvasView.drawing = PKDrawing()
    }
    
    // MARK: - UIImageView
    private func setupImageView() -> UIImageView {
        let img:UIImage = getDefaultImage()
        let imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        imgView.image = img
        imgView.contentMode = UIView.ContentMode.scaleAspectFit
        
        return imgView
    }
    
    // MARK: - Others
    // ビューのレイアウトを更新する
    func updateViewLayout(viewWidth:CGFloat, viewHeight:CGFloat)
    {
        if let templateImage = imageView.image {
            // PencilKitで描いた画像から抽出する領域を計算する
            var posX:CGFloat = 0
            var posY:CGFloat = 0
            var width:CGFloat = 0
            var height:CGFloat = 0
            // デバイスの幅と高さのどちらに合わせて画像を表示しているか判別させる
            if viewWidth/viewHeight < templateImage.size.width/templateImage.size.height
            {
                // デバイスの幅に合わせて画像を表示している場合
                width = viewWidth
                height = viewWidth * (templateImage.size.height/templateImage.size.width)
                posX = 0
                posY = (viewHeight - height) / 2
                
                _overlayViewSizeX = width
                _overlayViewSizeY = (viewHeight - height) / 2
                
                _overlayView_2_PosX = 0
                _overlayView_2_PosY = viewHeight - posY
            }
            else
            {
                // デバイスの高さに合わせて画像を表示している場合
                width = viewHeight  * (templateImage.size.width/templateImage.size.height)
                height = viewHeight
                posX = (viewWidth - width) / 2
                posY = 0
                
                _overlayViewSizeX = (viewWidth - width) / 2
                _overlayViewSizeY = height
                
                _overlayView_2_PosX = viewWidth - posX
                _overlayView_2_PosY = 0
            }
        }
        // ビューの位置とサイズを設定
        canvasView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        imageView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        self._overlayView_1?.frame = CGRect(x: _overlayView_1_PosX, y: _overlayView_1_PosY, width: _overlayViewSizeX, height: _overlayViewSizeY)
        self._overlayView_2?.frame = CGRect(x: _overlayView_2_PosX, y: _overlayView_2_PosY, width: _overlayViewSizeX, height: _overlayViewSizeY)
        // キャンバスビューのズーム値をリセット
        canvasView.zoomScale = 1;
    }
    
    // デフォルトのUIImageを取得する
    public func getDefaultImage() -> UIImage
    {
        // 一時保存した画像を取り出す
        let fileURL = try! FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("sample.png")
        let img = UIImage(contentsOfFile: fileURL.path)!
        return img
    }
    
    // 描いた線とベース画像を合成して保存する
    public func saveCurrentPage()
    {
        if let templateImage = imageView.image {
            // 保存処理中フラグをtrueにする
            self._parent._pencilKitViewModel.m_isSaving = true
            // 保存処理完了フラグをfalseにする
            self._parent._pencilKitViewModel.m_isCompleteSave = false
            // PKCanvasView上のレンダリング情報とテンプレート画像を合成して一枚絵にする。
            // キャンバスのスクロールが有効の場合にはScrollView全域を対象とするためにContenSizeを使用する
            // let contentSize = self.canvasView.contentSize
            // PencilKitで描いた画像から抽出する領域を計算する
            var posX:CGFloat = 0
            var posY:CGFloat = 0
            var width:CGFloat = 0
            var height:CGFloat = 0
            // デバイスの幅と高さのどちらに合わせて画像を表示しているか判別させる
            if self.view.frame.width/self.view.frame.height < templateImage.size.width/templateImage.size.height
            {
                // デバイスの幅に合わせて画像を表示している場合
                width = self.view.frame.width
                height = self.view.frame.width * (templateImage.size.height/templateImage.size.width)
                posX = 0
                posY = (self.view.frame.height - height) / 2
            }
            else
            {
                // デバイスの高さに合わせて画像を表示している場合
                width = self.view.frame.height  * (templateImage.size.width/templateImage.size.height)
                height = self.view.frame.height
                posX = (self.view.frame.width - width) / 2
                posY = 0
            }
            // バックグラウンドで処理
            DispatchQueue.global(qos: .background).async(execute: { [self] in
                let contentRect = CGRect(x: posX, y: posY, width: width, height: height)
                // 画像を合成
                let drawImage = templateImage.composite(image: self.canvasView.drawing.image(from: contentRect, scale: templateImage.size.width/width))
                // 画像を保存
                saveImage(image: drawImage)
            })
        }
    }
    
    // 画像を保存する
    private func saveImage(image:UIImage)
    {
        // ファイル名
        let fileName = "sample.png"
        let newUrl = try! FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(fileName)
        // PNGをTempフォルダに保存
        do{
//            try image.jpegData(compressionQuality: 0.25)?.write(to: newUrl)
            try image.pngData()?.write(to: newUrl)
        }
        catch let error
        {
            print(error.localizedDescription)
        }
        DispatchQueue.main.async
        {
            // 保存先のURLを記録する
            self._parent.m_shareItemURL = newUrl
            // 保存処理中フラグをfalseにする
            self._parent._pencilKitViewModel.m_isSaving = false
            // 保存処理完了フラグをtrueにする
            self._parent._pencilKitViewModel.m_isCompleteSave = true
            // コールバック処理を実行する
            self._parent._pencilKitViewModel.m_doSaveCallback()
        }
    }
    
    // 画像を読み込む
    public func loadImage(urlStr:String)
    {
        // URLに変換
        let url:URL = URL(fileURLWithPath: urlStr)
        // ファイルの拡張子を取得する
        let ext = url.pathExtension
        // アプリ内のファイルパスの場合
        let image:UIImage = UIImage(contentsOfFile: urlStr)!
        // イメージビューに画像をセット
        ResetImageView(image: image)
        // ファイルを削除
        if !m_fileOperator.deleteFile(fileURL: url) {
            print("ファイルの削除に失敗")
        }
    }
    
    // ImageViewに画像をセットし、レイアウトをリセットする
    public func ResetImageView(image:UIImage)
    {
        // イメージビューに画像をセット
        imageView.image = image
        // レイアウトをリセット
        updateViewLayout(viewWidth: self.view.frame.width, viewHeight: self.view.frame.height)
    }
}

extension UIImage {

    func composite(image: UIImage) -> UIImage {

        UIGraphicsBeginImageContextWithOptions(self.size, false, 1)

        draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
//        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        image.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return image
    }
}
