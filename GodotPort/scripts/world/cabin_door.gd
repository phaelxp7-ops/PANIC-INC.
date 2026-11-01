class_name CabinDoor
extends AnimatableBody3D
## Porta física de cabana. O pivô fica na dobradiça, permitindo abrir sem teleporte.

const DURACAO: float = 0.42
var _aberta: bool = false
var _tween: Tween


func alternar() -> void:
	_aplicar_estado.rpc(not _aberta)


@rpc("authority", "call_local", "reliable")
func _aplicar_estado(aberta: bool) -> void:
	_aberta = aberta
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	var angulo: float = deg_to_rad(96.0) if _aberta else 0.0
	_tween.tween_property(self, "rotation:y", angulo, DURACAO)
