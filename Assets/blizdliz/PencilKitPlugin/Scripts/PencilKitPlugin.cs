using System;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;
using System.IO;

namespace iOSPencilKitPlugin
{
    public class PencilKitPlugin : MonoBehaviour
    {
        [Serializable] public class StringEvent : UnityEvent<string> { }
        [SerializeField] private StringEvent m_callbackEvent = default;

        /// <summary>
        /// PencilKitのビューを表示する
        /// </summary>
        /// <param name="oriTex"></param>
        public void ShowPencilKitView(Texture2D oriTex)
        {
#if !UNITY_EDITOR && UNITY_IOS
                // 画像を一時保存
                Texture2D tex = oriTex;
                var png = tex.EncodeToPNG();
                var filePath = Application.temporaryCachePath + "/sample.png";
                File.WriteAllBytes(filePath, png);
                // プラグインの呼び出し
                var ret = ShowPencilKitView();
                Debug.Log($"戻り値: {ret}");
#else
                // それ以外のプラットフォームからの呼び出し (Editor含む)
                Debug.Log("Hello World (iOS以外からの呼び出し)");
#endif
        }

        /// <summary>
        /// コールバック用関数
        /// </summary>
        /// <param name="message"></param>
        public void OnCloseCallback(string message)
        {
            Debug.Log("PencilKitAsset OnCloseCallback");
            // 画像のパスを取得
            var filePath = message;//Application.temporaryCachePath + "/sample.png";
            // コールバックを実行
            if (m_callbackEvent != null)
            {
                m_callbackEvent.Invoke(filePath);
            }
        }

        #region P/Invoke

        // Swiftで実装した`Example`クラスのP/Invoke

        /// <summary>
        /// `showPencilKitView`の呼び出し
        /// </summary>
        /// <remarks>
        /// NOTE: Example.swiftの`@_cdecl`で定義した関数をここで呼び出す
        /// - iOSのプラグインは静的に実行ファイルにリンクされるので、`DllImport`にはライブラリ名として「__Internal」を指定する必要がある
        /// - `EntryPoint`にSwift側で定義されている名前を渡すことでC#側のメソッド名は別名を指定可能
        /// </remarks>
        [DllImport("__Internal", EntryPoint = "showPencilKitView")]
        static extern bool ShowPencilKitView();


        // NOTE: ちなみに`EntryPoint`を指定しない場合は、以下のようにC#側もSwiftで定義されている関数名と同名に合わせる必要がある
        // [DllImport("__Internal")]
        // static extern Int32 printHelloWorld();

        #endregion P/Invoke
    }
}

