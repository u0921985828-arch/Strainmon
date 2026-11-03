# La maceta de tela de 35 L de la vista C (equipo_c.py: maceta-c-tela35-28) en godot/arte/carpa.png + carpa.json, uno de los
# sprites propios de la hoja: el HTML está congelado en la 1.37 y tools/godot.js no se vuelve a pasar. El sitio en la hoja lo
# reparte tools/carpa_hoja.py (ya no hay celdas a mano). python3 -I tools/maceta35.py
import os, sys
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(R, 'tools', 'sprites', 'a-mano'))
sys.path.insert(0, os.path.join(R, 'tools'))
os.chdir(R)
import equipo_c
import carpa_hoja
N = 'maceta-c-tela35-28'
im = equipo_c.SAL['carpa-c-macetas-b'][N][0].im
carpa_hoja.abre()
carpa_hoja.pon(N, im)
tam, nm = carpa_hoja.guarda()
print(N, im.getbbox(), 'carpa.png %dx%d, %d fotogramas propios' % (tam[0], tam[1], nm))
