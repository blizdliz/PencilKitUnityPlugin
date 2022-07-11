//
//  FileOperator.swift
//  UnityFramework
//
//  Created by 小宮和貴 on 2022/07/06.
//

import Foundation

// ファイル操作を行う
struct FileOperator
{
    private let _fileManager = FileManager.default
    
    // ファイルを削除する
    public func deleteFile(fileURL: URL) -> Bool
    {
        do {
            try _fileManager.removeItem(at: fileURL)
        } catch {
            print("ファイルまたはフォルダの削除に失敗")
            return false
        }
        return true
    }
    
    /// ファイル書き込みサンプル
    func writingToFile(text: String, fileName: String) -> URL
    {
        /// ①DocumentsフォルダURL取得
        let dirURL = _fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        /// ②対象のファイルURL取得
        let fileURL = dirURL.appendingPathComponent(fileName)
        /// ③ファイルの書き込み
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("書き込みエラー: \(error)")
        }
        /// 保存先のURLを返す
        return fileURL
    }
}

