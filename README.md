# OpenCode Go Widget

Widget de barra de menu para macOS que consulta el uso de OpenCode Go y guarda la API key en el Keychain del sistema.

## Requisitos

- macOS 13 o posterior
- Xcode 15 o posterior

## Ejecutar

```bash
swift run
```

En el primer inicio, abre `Configuración` y registra tu API key. La aplicación consulta el endpoint cada 15 minutos y permite actualizar manualmente.

## Probar

```bash
swift test
```

## Build

```bash
swift build -c release
```

El binario queda en `.build/arm64-apple-macosx/release/OpenCodeGoWidget`.

## Seguridad

La API key no se escribe en archivos del proyecto ni en logs. Se almacena mediante Keychain Services.
