# Room Scanner AR

Aplicación de escaneo de habitaciones en Realidad Aumentada y generación de planos 2D.

## Descripción

Room Scanner AR permite escanear los vértices de una habitación usando la cámara y sensores AR del dispositivo, validar la geometría del polígono resultante, editar el plano 2D de forma interactiva (arrastrar vértices, añadir puertas y ventanas) y exportar el resultado como imagen PNG o documento PDF.

## Características

- **Escaneo AR**: Captura esquinas de habitaciones usando ARCore (Android) / ARKit (iOS).
- **Filtro de estabilidad**: Algoritmo EMA + varianza para descartar lecturas ruidosas.
- **Validación geométrica**: Detección de autointersecciones, duplicados y cierre automático.
- **Editor 2D interactivo**: Arrastra vértices, añade puertas/ventanas con posición y ancho configurables.
- **Exportación**: PNG rasterizado (vía `RepaintBoundary`) o PDF vectorial con tabla de métricas.
- **Material 3**: Interfaz moderna con tema dinámico.

## Requisitos

### Dispositivo
- **Android**: API 24+ (Android 7.0+) con soporte ARCore. [Lista de dispositivos compatibles](https://developers.google.com/ar/devices)
- **iOS**: iOS 13+ con soporte ARKit (iPhone 6s o superior).

### Software
- Flutter >= 3.16.0
- Dart SDK >= 3.0.0 < 4.0.0

## Dependencias principales

| Paquete | Versión | Uso |
|---------|---------|-----|
| `ar_flutter_plugin` | local | Sesión AR, hit-test, nodos 3D |
| `provider` | ^6.1.2 | Gestión de estado |
| `pdf` | ^3.10.8 | Generación de PDF vectorial |
| `printing` | ^5.13.1 | Renderizado de PDF |
| `share_plus` | ^9.0.0 | Compartir archivos exportados |
| `path_provider` | ^2.1.3 | Directorio temporal |
| `vector_math` | ^2.1.4 | Operaciones 3D |
| `permission_handler` | ^11.3.0 | Permisos de cámara y almacenamiento |

## Instrucciones de build

### 1. Clonar el repositorio

```bash
git clone https://github.com/BetOarg/room_scanner_ar.git
cd room_scanner_ar
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar permisos nativos

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-feature android:name="android.hardware.camera.ar" android:required="true" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>La cámara se usa para el escaneo de habitaciones en realidad aumentada.</string>
```

### 4. Ejecutar

```bash
# Modo debug
flutter run

# Modo release (recomendado para AR)
flutter run --release
```

## Estructura del proyecto

```
lib/
├── controllers/
│   └── ar_scan_controller.dart      # Controlador de sesión AR y captura
├── models/
│   ├── scan_point.dart              # Vértice 3D con serialización
│   ├── projected_point.dart         # Proyección 2D cacheada
│   └── wall_opening.dart            # Puertas y ventanas
├── providers/
│   └── scan_notifier.dart           # Estado unificado del escaneo
├── screens/
│   ├── scan_screen.dart             # Vista AR + captura
│   └── floor_plan_screen.dart       # Editor 2D + exportación
├── services/
│   ├── ar_session_service.dart      # Wrapper del plugin AR
│   └── permission_service.dart      # Manejo de permisos nativos
├── utils/
│   ├── measurements.dart            # Cálculo de área, perímetro, proyección 2D
│   ├── scan_validator.dart          # Validación geométrica (intersecciones, duplicados)
│   ├── ar_stability_filter.dart     # Filtro EMA + varianza
│   ├── export_helper.dart           # Exportación PNG/PDF
│   └── pdf_floor_plan_painter.dart  # Pintor vectorial para PDF
├── widgets/
│   ├── ar_scan_view.dart            # Widget AR con overlay de estado
│   ├── ar_line_overlay.dart         # Líneas de guía sobre la cámara AR
│   └── floor_plan_canvas.dart       # Canvas 2D interactivo (gestos + pintor)
└── main.dart                        # Punto de entrada + Provider
```

## Testing

```bash
# Ejecutar todos los tests
flutter test

# Con cobertura
flutter test --coverage
```

## Licencia

Este proyecto está licenciado bajo la [Licencia MIT](LICENSE).
