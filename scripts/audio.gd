extends RefCounted

# ==========================================
# 音效合成器（v0.20.0）
# 全部用代码生成 PCM 波形，零外部素材、零版权风险
# 与项目「纯代码绘图」的理念一致
# ==========================================

const Data := preload("res://scripts/data.gd")

const SAMPLE_RATE := 22050


# 生成一个音效的 AudioStreamWAV
# 参数来自 Data.SFX 表
static func build(stream_name: String) -> AudioStreamWAV:
	if not Data.SFX.has(stream_name):
		return null

	var cfg: Dictionary = Data.SFX[stream_name]
	var duration := float(cfg["duration"])
	var volume := float(cfg["volume"])
	var decay := float(cfg["decay"])
	var f_start := float(cfg["freq_start"])
	var f_end := float(cfg["freq_end"])
	var kind := str(cfg["type"])

	var count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)

	var phase := 0.0
	# 噪声用固定种子，保证每次生成一致
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261028

	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration

		# 频率线性滑动
		var freq := lerpf(f_start, f_end, progress)

		var sample := 0.0
		match kind:
			"sine":
				phase += TAU * freq / float(SAMPLE_RATE)
				sample = sin(phase)
			"square":
				phase += TAU * freq / float(SAMPLE_RATE)
				sample = 1.0 if sin(phase) >= 0.0 else -1.0
			"noise":
				# 噪声混一点正弦，避免完全刺耳
				phase += TAU * freq / float(SAMPLE_RATE)
				sample = rng.randf_range(-1.0, 1.0) * 0.75 + sin(phase) * 0.25
			"sweep":
				phase += TAU * freq / float(SAMPLE_RATE)
				sample = sin(phase)
			"chord":
				# 三音和弦：基频 + 大三度 + 纯五度
				phase += TAU * freq / float(SAMPLE_RATE)
				sample = (
					sin(phase)
					+ sin(phase * 1.25) * 0.6
					+ sin(phase * 1.5) * 0.4
				) / 2.0
			_:
				sample = 0.0

		# 指数衰减包络
		var envelope := pow(maxf(0.0, 1.0 - progress), decay)

		# 开头 3ms 淡入，消除爆音
		var fade_in := minf(1.0, t / 0.003)
		envelope *= fade_in

		var value := sample * envelope * volume
		var int_value := int(clampf(value, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_value)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav


# 生成全部音效，返回 {名称: AudioStreamWAV}
static func build_all() -> Dictionary:
	var out := {}
	for key in Data.SFX.keys():
		var wav := build(str(key))
		if wav != null:
			out[str(key)] = wav
	return out
