# nova_license_sdk

Validación suave (*lazy*) de licencias para **apps de pago de NovaStore**.

Cuando un usuario compra una app en NovaStore, la compra queda vinculada a un
dispositivo concreto. Este SDK, integrado dentro de la app del desarrollador,
comprueba en cada arranque si el dispositivo que está ejecutando la app tiene
licencia.

## Características

- Valida contra `POST /validate` de la API de NovaStore por **`package_name`**.
- **Gracia offline de 3 días**: si la licencia ya era válida y no hay red, la
  app sigue abriéndose durante la gracia.
- **Anti re-firma**: si se informa el SHA-1 de firma del APK (`apkSha1`), un APK
  re-firmado por otra persona no pasa la validación.
- **Dos estilos de integración**: un *gate* todo-o-nada de 2 líneas, o una
  comprobación programática para que el desarrollador decida qué proteger
  (modo premium, trial, protección por funciones).

## Integración

### 1. Añade la dependencia

```yaml
dependencies:
  nova_license_sdk:
    git:
      url: https://github.com/NovaStoreCU/nova_license_sdk.git
      ref: v1.0.0
```

> Alternativa sin red git: descarga la carpeta y usa una ruta local
> (`path: ./nova_license_sdk`).

### Estilo A — Gate todo-o-nada (2 líneas, recomendado para empezar)

Envuelve toda la app. Sin licencia válida, el usuario solo ve la pantalla de
licencia de NovaStore:

```dart
import 'package:nova_license_sdk/nova_license_sdk.dart';

void main() {
  runApp(
    novaLicenseGuard(
      config: const NovaLicenseGuardConfig(
        apiBase: 'https://novastore.cu/api/v1', // base de la API v1
        storeUrl: 'https://novastore.cu',        // base de la tienda
        packageName: 'com.tuempresa.tujuego',    // package_name registrado en NovaStore
        storeSlug: 'tu-juego',                    // opcional: slug de la app en la tienda
        // apkSha1: 'AA:BB:...',                  // opcional: SHA-1 de firma del APK
      ),
      child: const TuApp(),
    ),
  );
}
```

Lo que verá el usuario:

- Dispositivo con licencia → se abre la app normalmente.
- Dispositivo sin licencia → pantalla de licencia con el **código del
  dispositivo** y las instrucciones:
  1. Abre la app en NovaStore.
  2. Toca Comprar y pega el código como *Código de activación*.
  3. Al confirmar, la app se desbloquea en ese dispositivo (reinstalarla no
     exige recompra; cambiar de teléfono sí).

### Estilo B — Comprobación programática (tú decides qué proteger)

En lugar de envolver toda la app, pide el estado de la licencia y actúa según
el resultado. Ideal para **niveles premium, trials o proteger solo ciertas
funciones**:

```dart
import 'package:nova_license_sdk/nova_license_sdk.dart';

Future<void> abrirApp() async {
  const config = NovaLicenseGuardConfig(
    apiBase: 'https://novastore.cu/api/v1',
    storeUrl: 'https://novastore.cu',
    packageName: 'com.tuempresa.tujuego',
    apkSha1: 'AA:BB:...', // opcional
  );

  final resultado = await NovaLicense.verify(config);

  if (resultado.allowed) {
    // Con licencia: abre todo.
    runApp(const MiApp(nivelPremium: true));
  } else if (resultado.offline) {
    // Sin red y sin licencia en caché fresca: decide tú (p. ej. modo offline).
    runApp(const MiApp(nivelPremium: false));
  } else {
    // Sin licencia: tú decides el paywall propio.
    runApp(const MiApp(nivelPremium: false));
  }
}
```

`NovaLicense.verify` devuelve un `NovaLicenseCheck` con:

| Campo          | Descripción |
|----------------|-------------|
| `status`       | `valid`, `invalid`, `offline` o `error`. |
| `allowed`      | `true` solo si la licencia es válida. |
| `offline`      | `true` si no hay red y no hay caché fresca. |
| `errorMessage` | Detalle del error (si lo hay). |
| `deviceCode`   | Código de activación del dispositivo (muéstralo en tu pantalla). |

> **Ambos estilos usan el mismo backend** (`POST /validate`). Este modo no
> cambia el servidor: solo te entrega la respuesta para que la uses como
> quieras.

## Opciones de configuración

| Parámetro       | Requerido | Descripción |
|-----------------|-----------|-------------|
| `apiBase`       | sí        | Base de la API v1 (ej. `https://novastore.cu/api/v1`). |
| `storeUrl`      | sí        | Base de la tienda para el botón "Comprar". |
| `packageName`   | sí        | `package_name` de tu app registrado en NovaStore. |
| `storeSlug`     | no        | Slug de tu app; si va, el botón abre el detalle directo. |
| `deviceId`      | no        | Id de dispositivo estable (opcional; el SDK lo persiste solo). |
| `apkSha1`       | no        | SHA-1 de firma del APK (muro anti re-firma). |
| `grace`         | no        | Gracia offline (por defecto **3 días**). |
| `httpTimeout`   | no        | Timeout de la validación (por defecto 10 s). |

## Licencia

Ver el repositorio de NovaStore. Uso comercial sujeto a las reglas de NovaStore.