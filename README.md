
# CompBall - 電子元件合成

本專案為國立臺灣科技大學資訊工程系「iOS 程式設計」課程之期末專題。
這是一款基於 SwiftUI 和 SpriteKit 開發的經典物理合成遊戲，主題為「電子元件合成升級」。

## 遊戲主題

遊戲將傳統的「合成大西瓜」玩法與電子元件結合。玩家將從基礎的電晶體、邏輯閘開始，一步步將它們合成為更高級的積體電路(IC)、處理器(CPU)，體驗電子元件的演進與升級之路。

## 遊戲模式 (Game Modes)

本遊戲提供兩種不同的挑戰模式：

### 1. 經典模式 (Classic Mode)

- **玩法**: 沒有時間限制，玩家可以隨意放下元件。當元件堆疊超過頂部警戒線時，遊戲結束。
- **目標**: 挑戰合成的極限，創造出最高級的元件，並獲得盡可能高的分數。

<p align="center">
  <img src="Screenshots\Simulator Screenshot - iPad Air 11-inch (M2) - 2025-05-25 at 22.54.25.png" width="800">
</p>

### 2. 計時模式 (Time Attack Mode)

- **玩法**: 在有限的時間內進行遊戲。時間結束後，根據最終分數進行結算。
- **目標**: 考驗玩家的反應速度與決策能力，在時間壓力下快速合成，爭取最高分。

<p align="center">
  <img src="Screenshots\Simulator Screenshot - iPad Air 11-inch (M2) - 2025-05-25 at 23.07.14.png" width="800">
</p>


## 分數與排行榜

遊戲會自動記錄您在不同模式下的最高分，並展示在排行榜上，讓您隨時查看自己的紀錄。

## 技術棧 (Tech Stack)

- **語言**: Swift
- **框架**: SwiftUI, SpriteKit

## 音樂素材 (Music Assets)

- BGM：「BGM 8-bit01」by 魔王魂（https://maou.audio/）
- Music: "BGM 8-bit01" by MaouDamashii (https://maou.audio/)

## 圖片與素材說明

- 遊戲元件圖片、背景與 app icon 為本課程專案準備的 AI 生成素材。
- 音樂、音效、圖片、截圖與課程報告不包含在 source-code MIT 授權範圍內，詳見 [ASSET_CREDITS.md](ASSET_CREDITS.md)。

## 授權

Source code is released under the MIT License. See [LICENSE](LICENSE).

The MIT License applies to the original source code only. Bundled audio,
generated images, screenshots, and course report material remain under their
own terms or are provided only as project demonstration assets.

---

## Repository

```bash
git clone https://github.com/Ning0612/compball-ios-game.git
cd compball-ios-game
```

---

Developed for [iOS Programing Final Project Game], Department of Computer Science NTUST, Spring 2025.
Author: [Ning / B11110524]
