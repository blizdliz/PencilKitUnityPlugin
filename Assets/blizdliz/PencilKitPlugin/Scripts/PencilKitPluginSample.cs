using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using System.IO;
using iOSPencilKitPlugin;

public class PencilKitPluginSample : MonoBehaviour
{
    [SerializeField, Header("PencilKitPlugin")] PencilKitPlugin m_pencilKitPlugin = default;
    [SerializeField] RawImage m_rawImage = default;
    [SerializeField] Texture2D m_defTexture = default;
    private Texture2D m_texture = default;

    void Start()
    {
        SetRawImage(m_defTexture);
    }

    /// <summary>
    /// ボタン押下時の処理
    /// </summary>
    public void OnClick_SampleButton()
    {
        m_pencilKitPlugin.ShowPencilKitView(m_texture);
    }

    /// <summary>
    /// RawImageにテクスチャをセットする
    /// </summary>
    /// <param name="texture"></param>
    public void SetRawImage(Texture2D texture)
    {
        if (m_texture != null)
        {
            Destroy(m_texture);
            m_texture = null;
        }
        m_texture = texture;
        m_rawImage.texture = m_texture;
    }

    public void SetRawImage(string filePath)
    {
        // 画像を読み込む
        byte[] byteData = File.ReadAllBytes(filePath);
        Texture2D texture = new Texture2D(0, 0, TextureFormat.RGBA32, false);
        texture.LoadImage(byteData);
        // 画像をセット
        SetRawImage(texture);
    }
}
