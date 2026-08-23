extends Node

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_VOICE: StringName = &"Voice"
const BUS_AMBIENCE: StringName = &"Ambience"

const DEFAULT_MASTER_VOLUME: float = 1.0
const DEFAULT_MUSIC_VOLUME: float = 1.0
const DEFAULT_SFX_VOLUME: float = 1.0
const DEFAULT_VOICE_VOLUME: float = 1.0
const DEFAULT_AMBIENCE_VOLUME: float = 1.0

const DEFAULT_MUSIC_FADE_TIME: float = 1.0
const DEFAULT_MUSIC_CROSSFADE_TIME: float = 1.0

const DEFAULT_DUCK_TRANSITION_TIME: float = 0.25

var _master_bus: int
var _music_bus: int
var _sfx_bus: int
var _voice_bus: int
var _ambience_bus: int

var _master_volume: float = DEFAULT_MASTER_VOLUME
var _music_volume: float = DEFAULT_MUSIC_VOLUME
var _sfx_volume: float = DEFAULT_SFX_VOLUME
var _voice_volume: float = DEFAULT_VOICE_VOLUME
var _ambience_volume: float = DEFAULT_AMBIENCE_VOLUME

var _music_player: AudioStreamPlayer
var _transition_music_player: AudioStreamPlayer

var _next_ticket_id: int = 0

var _music_transitions: Dictionary = {}

var _music_fade_tween: Tween
var _music_crossfade_tween: Tween

var _active_ducks: Dictionary = {}
var _bus_tweens: Dictionary = {}

var master_volume: float:
	get:
		return _master_volume

var music_volume: float:
	get:
		return _music_volume

var sfx_volume: float:
	get:
		return _sfx_volume

var voice_volume: float:
	get:
		return _voice_volume

var ambience_volume: float:
	get:
		return _ambience_volume

func set_master_volume(volume: float) -> void:
	_master_volume = clampf(volume, 0.0, 1.0)
	_apply_master_volume()


func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	_update_bus_target(BUS_MUSIC, 0.0)


func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	_update_bus_target(BUS_SFX, 0.0)


func set_voice_volume(volume: float) -> void:
	_voice_volume = clampf(volume, 0.0, 1.0)
	_update_bus_target(BUS_VOICE, 0.0)


func set_ambience_volume(volume: float) -> void:
	_ambience_volume = clampf(volume, 0.0, 1.0)
	_update_bus_target(BUS_AMBIENCE, 0.0)


func play_music(stream: AudioStream) -> void:
	_cancel_music_transitions()

	if stream == null:
		stop_music()
		return

	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.bus = BUS_MUSIC
		add_child(_music_player)

	_music_player.stream = stream
	_music_player.volume_db = 0.0
	_music_player.play()


func stop_music() -> void:
	_cancel_music_transitions()

	if _music_player != null:
		_music_player.stop()
		_music_player.stream = null
		_music_player.volume_db = 0.0

	if _transition_music_player != null:
		_transition_music_player.stop()
		_transition_music_player.stream = null
		_transition_music_player.volume_db = 0.0


func fade_music(stream: AudioStream, duration: float = DEFAULT_MUSIC_FADE_TIME) -> MusicTransitionTicket:
	_cancel_music_transitions()

	var ticket := _create_music_transition_ticket()

	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.bus = BUS_MUSIC
		add_child(_music_player)

	if not _music_player.playing:
		if stream == null:
			_complete_music_transition(ticket)
			return ticket

		_music_player.stream = stream
		_music_player.volume_db = -80.0
		_music_player.play()

		_music_transitions[ticket.id] = true

		_music_fade_tween = create_tween()
		_music_fade_tween.tween_property(
			_music_player,
			"volume_db",
			0.0,
			duration
		)
		_music_fade_tween.finished.connect(_complete_music_transition.bind(ticket))

		return ticket

	_music_transitions[ticket.id] = true

	_music_fade_tween = create_tween()

	_music_fade_tween.tween_property(
		_music_player,
		"volume_db",
		-80.0,
		duration
	)

	_music_fade_tween.tween_callback(func() -> void:
		if _music_player != null:
			_music_player.stop()
			_music_player.stream = null
			_music_player.volume_db = 0.0

		if stream == null:
			_complete_music_transition(ticket)
			return

		_music_player.stream = stream
		_music_player.volume_db = -80.0
		_music_player.play()

		_music_fade_tween = create_tween()
		_music_fade_tween.tween_property(
			_music_player,
			"volume_db",
			0.0,
			duration
		)
		_music_fade_tween.finished.connect(
			_complete_music_transition.bind(ticket)
		)

	)

	return ticket


func crossfade_music(stream: AudioStream, duration: float = DEFAULT_MUSIC_CROSSFADE_TIME) -> MusicTransitionTicket:
	_cancel_music_transitions()

	if stream == null:
		return fade_music(null, duration)

	var ticket := _create_music_transition_ticket()

	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.bus = BUS_MUSIC
		add_child(_music_player)

	if not _music_player.playing:
		_music_player.stream = stream
		_music_player.volume_db = -80.0
		_music_player.play()

		_music_transitions[ticket.id] = true

		_music_crossfade_tween = create_tween()
		_music_crossfade_tween.tween_property(
			_music_player,
			"volume_db",
			0.0,
			duration
		)
		_music_crossfade_tween.finished.connect(_complete_music_transition.bind(ticket))

		return ticket

	if _transition_music_player == null:
		_transition_music_player = AudioStreamPlayer.new()
		_transition_music_player.bus = BUS_MUSIC
		add_child(_transition_music_player)

	_transition_music_player.stream = stream
	_transition_music_player.volume_db = -80.0
	_transition_music_player.play()

	_music_transitions[ticket.id] = true

	_music_crossfade_tween = create_tween().set_parallel(true)

	_music_crossfade_tween.tween_property(
		_music_player,
		"volume_db",
		-80.0,
		duration
	)

	_music_crossfade_tween.tween_property(
		_transition_music_player,
		"volume_db",
		0.0,
		duration
	)

	_music_crossfade_tween.finished.connect(func() -> void:
		if _music_player != null:
			_music_player.stop()
			_music_player.stream = null
			_music_player.volume_db = 0.0

		var old_player := _music_player
		_music_player = _transition_music_player
		_transition_music_player = old_player

		_complete_music_transition(ticket)
	)

	return ticket


func wait_for_music_transition(ticket: MusicTransitionTicket) -> void:
	if ticket == null:
		return

	var state: MusicTransitionState = _music_transitions.get(ticket.id)

	if state == null:
		return

	await state.finished


func duck(
	channel: StringName,
	amount: float,
	transition_time: float = DEFAULT_DUCK_TRANSITION_TIME
) -> DuckTransitionTicket:
	if channel == BUS_MASTER:
		Log.warn("Cannot duck the Master audio bus")
		return null

	if not _is_duckable_channel(channel):
		Log.warn("Cannot duck unknown audio channel: %s" % channel)
		return null

	var ticket := DuckTransitionTicket.new(_next_ticket_id)
	_next_ticket_id += 1

	amount = clampf(amount, 0.0, 1.0)
	transition_time = maxf(transition_time, 0.0)

	_active_ducks[ticket.id] = DuckState.new(
		channel,
		amount,
		transition_time
	)

	_update_bus_target(channel, transition_time)

	return ticket


func restore(ticket: DuckTransitionTicket) -> void:
	if ticket == null:
		Log.warn("Cannot restore null duck ticket")
		return

	var state: DuckState = _active_ducks.get(ticket.id)

	if state == null:
		Log.warn("Cannot restore unknown duck ticket: %s" % ticket.id)
		return

	var elapsed := float(Time.get_ticks_msec() - state.start_time) / 1000.0
	var progress := 1.0

	if state.transition_time > 0.0:
		progress = clampf(
			elapsed / state.transition_time,
			0.0,
			1.0
		)

	_active_ducks.erase(ticket.id)

	var restore_time := state.transition_time * (1.0 - progress)

	_update_bus_target(state.channel, restore_time)


func _ready() -> void:
	_setup_buses()
	_apply_all_volumes()


func _setup_buses() -> void:
	_master_bus = AudioServer.get_bus_index(BUS_MASTER)
	
	_music_bus = _get_or_create_bus(BUS_MUSIC)
	_sfx_bus = _get_or_create_bus(BUS_SFX)
	_voice_bus = _get_or_create_bus(BUS_VOICE)
	_ambience_bus = _get_or_create_bus(BUS_AMBIENCE)

	AudioServer.set_bus_send(_music_bus, BUS_MASTER)
	AudioServer.set_bus_send(_sfx_bus, BUS_MASTER)
	AudioServer.set_bus_send(_voice_bus, BUS_MASTER)
	AudioServer.set_bus_send(_ambience_bus, BUS_MASTER)


func _get_or_create_bus(bus_name: StringName) -> int:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index != -1:
		return bus_index

	bus_index = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus_index, bus_name)

	return bus_index


func _apply_all_volumes() -> void:
	_apply_master_volume()
	_apply_music_volume()
	_apply_sfx_volume()
	_apply_voice_volume()
	_apply_ambience_volume()


func _apply_master_volume() -> void:
	AudioServer.set_bus_volume_db(_master_bus, linear_to_db(_master_volume))


func _apply_music_volume() -> void:
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(_music_volume))


func _apply_sfx_volume() -> void:
	AudioServer.set_bus_volume_db(_sfx_bus, linear_to_db(_sfx_volume))


func _apply_voice_volume() -> void:
	AudioServer.set_bus_volume_db(_voice_bus, linear_to_db(_voice_volume))


func _apply_ambience_volume() -> void:
	AudioServer.set_bus_volume_db(_ambience_bus, linear_to_db(_ambience_volume))


func _create_music_transition_ticket() -> MusicTransitionTicket:
	var ticket := MusicTransitionTicket.new(_next_ticket_id)
	_next_ticket_id += 1

	_music_transitions[ticket.id] = MusicTransitionState.new()

	return ticket


func _complete_music_transition(ticket: MusicTransitionTicket) -> void:
	if ticket == null:
		return

	var state: MusicTransitionState = _music_transitions.get(ticket.id)

	if state == null:
		return

	_music_transitions.erase(ticket.id)
	state.finished.emit()


func _cancel_music_transitions() -> void:
	if _music_fade_tween != null and _music_fade_tween.is_valid():
		_music_fade_tween.kill()

	if _music_crossfade_tween != null and _music_crossfade_tween.is_valid():
		_music_crossfade_tween.kill()

	_music_fade_tween = null
	_music_crossfade_tween = null

	if _transition_music_player != null:
		_transition_music_player.stop()
		_transition_music_player.stream = null
		_transition_music_player.volume_db = 0.0

	var tickets_to_complete := _music_transitions.keys()

	for ticket_id in tickets_to_complete:
		var ticket := MusicTransitionTicket.new(ticket_id)
		_complete_music_transition(ticket)


func _is_duckable_channel(channel: StringName) -> bool:
	return (
		channel == BUS_MUSIC
		or channel == BUS_SFX
		or channel == BUS_VOICE
		or channel == BUS_AMBIENCE
	)


func _get_duck_amount(channel: StringName) -> float:
	var strongest_duck := 0.0

	for state_variant in _active_ducks.values():
		var state: DuckState = state_variant

		if state.channel != channel:
			continue

		strongest_duck = maxf(
			strongest_duck,
			state.amount
		)

	return strongest_duck


func _update_bus_target(
	channel: StringName,
	transition_time: float
) -> void:
	var base_volume := _get_base_volume(channel)
	var duck_amount := _get_duck_amount(channel)

	var target_volume := base_volume * (1.0 - duck_amount)

	_transition_bus_volume(
		channel,
		target_volume,
		transition_time
	)


func _transition_bus_volume(
	channel: StringName,
	target_volume: float,
	transition_time: float
) -> void:
	var bus_index := _get_bus_index(channel)

	if bus_index == -1:
		return

	var previous_tween: Tween = _bus_tweens.get(channel)

	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()

	_bus_tweens.erase(channel)

	var target_db := linear_to_db(
		maxf(target_volume, 0.0001)
	)

	var current_db := AudioServer.get_bus_volume_db(bus_index)

	if transition_time <= 0.0:
		AudioServer.set_bus_volume_db(
			bus_index,
			target_db
		)
		return

	var tween := create_tween()
	_bus_tweens[channel] = tween

	tween.tween_method(
		func(value: float) -> void:
			AudioServer.set_bus_volume_db(
				bus_index,
				value
			),
		current_db,
		target_db,
		transition_time
	)

	tween.finished.connect(func() -> void:
		if _bus_tweens.get(channel) == tween:
			_bus_tweens.erase(channel)
		)


func _get_base_volume(channel: StringName) -> float:
	match channel:
		BUS_MUSIC:
			return _music_volume
		BUS_SFX:
			return _sfx_volume
		BUS_VOICE:
			return _voice_volume
		BUS_AMBIENCE:
			return _ambience_volume
		_:
			return 0.0


func _get_bus_index(channel: StringName) -> int:
	match channel:
		BUS_MASTER:
			return _master_bus
		BUS_MUSIC:
			return _music_bus
		BUS_SFX:
			return _sfx_bus
		BUS_VOICE:
			return _voice_bus
		BUS_AMBIENCE:
			return _ambience_bus
		_:
			return -1


class MusicTransitionState:
	signal finished

class DuckState:
	var channel: StringName
	var amount: float
	var transition_time: float
	var start_time: int

	func _init(channel: StringName, amount: float, transition_time: float) -> void:
		self.channel = channel
		self.amount = amount
		self.transition_time = transition_time
		self.start_time = Time.get_ticks_msec()
