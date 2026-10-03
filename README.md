# AquaRings

Juego de agua con minibalones de baloncesto. Nueve balones flotan dentro de un
tanque con una canasta en el techo. Dos bombas en la base soplan chorros de agua
que empujan a todos los balones a la vez. Tu único trabajo es elegir en qué
momento y con qué fuerza disparar los chorros para encestar.

No hay control por personaje: los balones son cuerpos rígidos con física real y
se mueven solos. Adivinar su trayectoria es el juego.

---

## Descargas

| Plataforma | Archivo | Notas |
|---|---|---|
| Windows 64-bit | `AquaRings.exe` | Windows 10 o superior |
| Windows 32-bit | `AquaRings_x86_32.exe` | Solo para sistemas de 32 bits |
| macOS | `AquaRings.zip` | Universal: Intel y Apple Silicon |
| Linux | `AquaRings.x86_64` | Marca el archivo como ejecutable |

Descomprime el `.zip` y ejecuta el binario. No necesita instalar nada.

Si tu plataforma no aparece aquí, puedes compilar el juego tú mismo desde el
código fuente: ver [Compilar desde el código](#compilar-desde-el-código).

---

## Controles

| Acción | Teclado | Ratón |
|---|---|---|
| Bomba izquierda | `A` o `←` | Click izquierdo del tanque |
| Bomba derecha | `D` o `→` | Click derecho del tanque |
| Ambas bombas | `Espacio` | — |
| Reiniciar | `R` o botón *Reset* | — |

El click decide de lado por la mitad de la pantalla en la que hagas click, no
por la del tanque.

### Cómo se marca un punto

Un balón suma cuando cae por el aro **centrado, despacio y desde arriba**. Los
tiros laterales rápidos no cuentan, y un balón que asoma por debajo del aro y
vuelve a subir no engaña al detector. Si un balón encestado se sale de la zona
del aro, pierde el punto.

---

## Requisitos

- Windows 10+, macOS 10.13+ o una distribución de Linux de 2018 en adelante.
- Tarjeta gráfica con OpenGL 3.3. Sirve cualquier GPU integrada: el juego usa el
  renderer de compatibilidad, no Vulkan.
- 2 GB de RAM.

---

## Compilar desde el código

Necesitas [Godot 4.7](https://godotengine.org/download) o superior. No hay
dependencias adicionales ni plugins.

```bash
git clone <url-del-repo>
cd AquaRings
```

**Para jugar:** abre el proyecto en Godot y pulsa `F5`.

**Para exportar:** `Editor > Manage Export Templates`, descarga las plantillas
de la 4.7, y luego `Project > Export`. Cada destino genera un binario
independiente.

Los `.import` de los assets son necesarios. Si Godot no los regenera al abrir,
borra la carpeta `.godot/` y vuelve a abrir el proyecto.

---

## Estructura

```
scenes/
  main.tscn      Tanque, paredes, aro, valvula, UI y particulas
  ball.tscn      Minibalon (RigidBody2D)
  ring.tscn      Aro flotante (RigidBody2D, todavia no se instancia)
scripts/
  main.gd        Gestor: generacion, puntaje, deteccion de canasta, entrada
  ball.gd        Flotacion, vaiven y chorros de bomba
  ring.gd        Igual que ball.gd pero para aros
shaders/
  fondo_oceano.gdshader   Fondo degradado procedural, animado con TIME
tools/
  generate_tree_toy.py    Genera tree_toy.png (requiere Pillow)
```

### Decisiones que no son obvias al leer el código

**El fondo no se toca desde el código.** `fondo_oceano.gdshader` se pinta en un
`ColorRect` a pantalla completa y el ciclo lo lleva `TIME`, así que `main.gd`
nunca lo actualiza. Cuesta un quad a pantalla completa por frame.

**Hay dos capas contra el fraude.** Un aro invisible con colisión unidireccional
en `main.tscn` impide que un balón suba por el aro a nivel físico, y
`main.gd` añade un segundo tope por código (`VALVE_HALF_WIDTH`) que lo hace
imposible incluso si hay tunelado a alta velocidad. El `Area2D` de anotado es
solo un respaldo: la detección real es el cruce del plano del aro de arriba hacia
abajo, que no depende del timing de entrada.

**`ring.gd` y `ring.tscn` están listos pero sin usar.** No hay ningún nodo de aro
instanciado en `main.tscn`.

**Las constantes están duplicadas en `ball.tscn` y `ball.gd`.** Las asignaciones
de `_ready()` son las que ganan, así que si tocas masa o material, toca también
el script.

---

## Créditos

Gráficos generados con `tools/generate_tree_toy.py`. Motor: Godot 4.7.