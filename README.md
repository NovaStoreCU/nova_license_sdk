# nova_license_sdk

Validación suave (*lazy*) de licencias para **apps de pago de NovaStore**.

Cuando un usuario compra una app en NovaStore, la compra queda vinculada a un
dispositivo concreto. Este SDK, integrado dentro de la app del desarrollador,
comprueba en cada arranque si el dispositivo que está ejecutando la app tiene
licencia. Solo **2 líneas** de integración.

## Características

- Valida contra `POST /validate` de la API de NovaStore por **`package_name`**.
- **Gracia offline de 3 días**: si la licencia ya era válida y no hay red, la
  app sigue abriéndose durante la gracia.
- **Anti re-firma**: si se informa el SHA-1 de firma del APK (`apkSha1`), un APK
  re-firmado por otra persona no pasa la validación.
- Si no hay licencia, muestra una pantalla con el **código de dispositivo** que
  el usuario pega en NovaStore al comprar (vínculo manual) y un botón que abre
  la tienda.

## Integración (3 pasos)

### 1. Añade la dependencia

```yaml
dependencies:
  nova_license_sdk:
    git:
      url: https://github.com/NovaStoreCU/nova_license_sdk.git
      ref: v1.0.0
```

> Alternativa sin red git: descarga el zip/la carpeta y usa una ruta local
> (`path: ./nova_license_sdk`).

### 2. Envuelve tu app

```dart
import 'package:nova_license_sdk/nova_license_sdk.dart';

void main() {
  runApp(
    novaLicenseGuard(
      config: const NovaLicenseGuardConfig(
        apiBase: 'https://novastore.cu/api/v1', // base de la API v1
        storeUrl: 'https://novastore.cu',        // base de la tienda
        packageName: 'com.tuempresa.tujuego',    // package_name registrado en NovaStore
        storeSlug: 'tu-juego',                    // opcional: sluge para el botón de compra
        // apkSha1: 'AA:BB:...',                  // opcional: SHA-1 de firma del APK
      ),
      child: const TuApp(),
    ),
  );
}
```

### 3. Compila y así lo ve el usuario

- Dispositivo con licencia → se abre la app normalmente.
- Dispositivo sin licencia → pantalla de licencia con el **código del
  dispositivo** y las instrucciones:
  1. Abre la app en NovaStore.
  2. Toca Comprar y pega el código como *Código de activación*.
  3. Al confirmar, la app se desbloquea en ese dispositivo (reinstalarla no exige
     recompra; cambiar de teléfono sí).

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