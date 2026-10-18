# Triángulo con coordenadas baricéntricas

Rasteriza un triángulo píxel por píxel en Zig + raylib. Para cada píxel `P` dentro del bounding box se calculan sus coordenadas baricéntricas con la fórmula del área (con signo):

```
u = área(P, B, C) / área(A, B, C)
v = área(A, P, C) / área(A, B, C)
w = área(A, B, P) / área(A, B, C)
área(P0, P1, P2) = ((x1 - x0)(y2 - y0) - (x2 - x0)(y1 - y0)) / 2
```

Si `u, v, w >= 0` el píxel pertenece al triángulo y su color es `(u·255, v·255, w·255)`: rojo en A, verde en B y azul en C, cada uno más intenso al acercarse a su vértice.

## Uso

```
zig build run
zig build test
```

- `1`, `2`, `3`: cambian entre los tres triángulos de ejemplo
- Arrastrar un vértice con el mouse: deforma el triángulo en tiempo real

Probado con Zig 0.16.0.
