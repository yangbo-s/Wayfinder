# Wayfinder 剪切提示音候选

五个音效均从随机噪声、滤波器和短包络程序合成，没有使用 Command X、系统音效或第三方录音的采样。音频和生成代码采用随包附带的 MIT License，可修改并随 Wayfinder 一起发布。

| 编号 | 风格 | 长度 | 文件 |
|---|---|---|---|
| 最早试听 | 轻快剪切 | 105 ms | E-original-snip.wav |
| A | 金属剪刀，短促咔嚓 | 155 ms | A-metallic-snip.wav |
| B | 剪纸，带一点摩擦质感 | 215 ms | B-paper-cut.wav |
| C | 柔和短划，无音高旋律 | 170 ms | C-soft-swipe.wav |
| D | 两下紧凑机械点击 | 125 ms | D-double-tick.wav |

`compare-five.wav` 按轻快剪切 → A → B → C → D 播放两轮，音效间隔一秒。它只供试听，不作为 App 音效。

文件格式：48 kHz、16-bit linear PCM、单声道 WAV。前后淡入淡出，零起止采样，峰值保留至少 3 dB 余量。实际测量见 `metrics.json`。五个声音已接入 App 的“权限与设置”，可选择与试听，默认最早制作的轻快剪切。

重新生成：`python3 generate.py`。只需要 Python 标准库；固定随机种子保证在相同 Python 环境中可复现。
