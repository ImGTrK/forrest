class_name SfxSynth
extends RefCounted
## Efectos de sonido sintetizados por código (placeholders). Cada receta es un tono que barre de
## f0 a f1 + ruido filtrado, con una envolvente de ataque y caída. Se generan 3 variantes por id
## (frecuencia y semilla distintas) para que golpes seguidos no suenen idénticos.
## Cuando haya sonidos reales en assets/audio/sfx/, AudioManager los usa en vez de estos.

const MIX_RATE := 22050

## dur: segundos · wave: sine/square/tri/none · f0→f1: barrido del tono (Hz)
## tone/noise: volumen de cada parte · lp0→lp1: brillo del ruido (0..1, filtro pasabajos)
## attack: segundos hasta el pico · decay: qué tan rápido cae (más = más seco)
## am: modulación de amplitud en Hz (raspado) · vib: vibrato en Hz (aturdido)
const RECIPES := {
	&"swing": {"dur": 0.14, "wave": "none", "noise": 0.9, "lp0": 0.04, "lp1": 0.32, "attack": 0.05, "decay": 9.0},
	&"dash": {"dur": 0.2, "wave": "none", "noise": 0.8, "lp0": 0.03, "lp1": 0.22, "attack": 0.07, "decay": 7.0},
	&"hit": {"dur": 0.13, "wave": "sine", "f0": 170.0, "f1": 55.0, "tone": 0.9, "noise": 0.35, "lp0": 0.45, "lp1": 0.1, "attack": 0.002, "decay": 24.0},
	&"enemy_die": {"dur": 0.34, "wave": "square", "f0": 430.0, "f1": 85.0, "tone": 0.3, "noise": 0.45, "lp0": 0.35, "lp1": 0.05, "attack": 0.003, "decay": 8.0},
	&"player_hurt": {"dur": 0.2, "wave": "square", "f0": 340.0, "f1": 140.0, "tone": 0.4, "noise": 0.3, "lp0": 0.5, "lp1": 0.1, "attack": 0.002, "decay": 13.0},
	&"player_die": {"dur": 0.7, "wave": "tri", "f0": 440.0, "f1": 105.0, "tone": 0.6, "noise": 0.1, "lp0": 0.2, "lp1": 0.02, "attack": 0.01, "decay": 3.5},
	&"chop": {"dur": 0.09, "wave": "sine", "f0": 220.0, "f1": 150.0, "tone": 0.7, "noise": 0.6, "lp0": 0.55, "lp1": 0.15, "attack": 0.001, "decay": 38.0},
	&"mine": {"dur": 0.22, "wave": "tri", "f0": 1550.0, "f1": 1480.0, "tone": 0.45, "noise": 0.35, "lp0": 0.9, "lp1": 0.3, "attack": 0.001, "decay": 20.0},
	&"break": {"dur": 0.28, "wave": "sine", "f0": 140.0, "f1": 60.0, "tone": 0.6, "noise": 0.7, "lp0": 0.6, "lp1": 0.05, "attack": 0.002, "decay": 10.0},
	&"spit": {"dur": 0.1, "wave": "sine", "f0": 720.0, "f1": 170.0, "tone": 0.8, "noise": 0.2, "lp0": 0.4, "lp1": 0.1, "attack": 0.003, "decay": 28.0},
	&"pop": {"dur": 0.08, "wave": "sine", "f0": 420.0, "f1": 120.0, "tone": 0.6, "noise": 0.5, "lp0": 0.6, "lp1": 0.2, "attack": 0.001, "decay": 40.0},
	&"scrape": {"dur": 0.5, "wave": "none", "noise": 0.9, "lp0": 0.06, "lp1": 0.12, "attack": 0.1, "decay": 2.5, "am": 16.0},
	&"bonk": {"dur": 0.3, "wave": "sine", "f0": 320.0, "f1": 170.0, "tone": 0.8, "noise": 0.25, "lp0": 0.5, "lp1": 0.1, "attack": 0.002, "decay": 9.0, "vib": 22.0},
}

const VARIANTS := 3


static func has(id: StringName) -> bool:
	return RECIPES.has(id)


static func make(id: StringName) -> Array[AudioStream]:
	var out: Array[AudioStream] = []
	if not RECIPES.has(id):
		return out
	for v in VARIANTS:
		out.append(render(RECIPES[id], v))
	return out


static func render(r: Dictionary, variant := 0) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(r)) + variant * 7919
	var detune := 1.0 + (variant - 1) * 0.06
	var dur: float = r.dur
	var n := int(dur * MIX_RATE)
	var wave: String = r.get("wave", "none")
	var f0: float = r.get("f0", 0.0) * detune
	var f1: float = r.get("f1", 0.0) * detune
	var tone_amp: float = r.get("tone", 0.0)
	var noise_amp: float = r.get("noise", 0.0)
	var lp0: float = r.get("lp0", 0.3)
	var lp1: float = r.get("lp1", 0.3)
	var attack: float = maxf(r.get("attack", 0.005), 0.0005)
	var decay: float = r.get("decay", 10.0)
	var am: float = r.get("am", 0.0)
	var vib: float = r.get("vib", 0.0)

	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		var k := t / dur
		# Envolvente: subida lineal y caída exponencial, con un fundido final para no hacer "clic"
		var env := t / attack if t < attack else exp(-(t - attack) * decay)
		env *= minf(1.0, (dur - t) * 60.0)
		if am > 0.0:
			env *= 0.55 + 0.45 * sin(TAU * am * t)
		var s := 0.0
		if wave != "none" and tone_amp > 0.0:
			var f := f0 * pow(f1 / f0, k) if f0 > 0.0 and f1 > 0.0 else f0
			if vib > 0.0:
				f *= 1.0 + 0.06 * sin(TAU * vib * t)
			phase = fmod(phase + f / MIX_RATE, 1.0)
			var w := 0.0
			match wave:
				"sine": w = sin(TAU * phase)
				"square": w = 1.0 if phase < 0.5 else -1.0
				"tri": w = 4.0 * absf(phase - 0.5) - 1.0
			s += w * tone_amp
		if noise_amp > 0.0:
			lp += lerpf(lp0, lp1, k) * (rng.randf_range(-1.0, 1.0) - lp)
			s += lp * noise_amp * 2.2
		var v := clampf(s * env * 0.55, -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
