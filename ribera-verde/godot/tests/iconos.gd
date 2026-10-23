# Landrace Hunters (Godot) — 1.58 (lo pidió el usuario: «faltan iconos»): cada icono que piden los menús, la tienda,
# la mochila y el equipo existe en el atlas (Atlas.icono no da null).
#   $GODOT --headless --path godot --script res://tests/iconos.gd   → «iconos: N comprobaciones, 0 fallos»
extends SceneTree

const Atlas = preload("res://src/atlas.gd")
const Datos = preload("res://src/datos.gd")

var n := 0
var fallos := []

func _initialize() -> void:
	Atlas.carga()
	var D = Datos.carga()
	var IC := {"fert": "abono", "fertv": "abono", "phm": "abono", "ofert": "abono", "ofertv": "abono", "ophm": "abono", "insect": "insecticida", "spray": "spray", "bocata": "bocadillo"}
	var nombres := {}
	for k in ["abono", "altavoz", "billetes", "bocadillo", "bolsa", "cogollo", "guardar", "insecticida", "maceta", "movil", "salir", "semillas", "spray", "trofeo", "corazon", "led", "lampara", "armario", "carpa"]:
		nombres[k] = "código"
	for k in Atlas.ICX:
		nombres[Atlas.ICX[k]] = "ICX." + k
	for it in D.SHOP + D.PARAFERNALIA:
		if it.get("ic"):
			nombres[it.ic] = "tienda " + str(it.get("lbl", ""))
		elif it.get("item") and IC.has(it.item):
			nombres[IC[it.item]] = "tienda " + str(it.get("lbl", ""))
	for k in nombres:
		n += 1
		if Atlas.icono(k) == null:
			fallos.append("falta el icono «%s» (%s)" % [k, nombres[k]])
	for k in D.STRAINS:
		n += 1
		if Atlas.icono_cogollo({"custom": {}}, k) == null:
			fallos.append("falta el cogollo de " + k)
	for f in fallos:
		print("FALLO ", f)
	print("iconos: %d comprobaciones, %d fallos" % [n, fallos.size()])
	quit(1 if fallos else 0)
