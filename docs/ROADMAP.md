# Roadmap y Plan Open Source

Este documento concentra futuras implementaciones, mejoras y los pasos para publicar
OpenCode Go Widget como proyecto open source en GitHub.

## Estado actual

- Widget de barra de menú para macOS.
- Consulta el endpoint de usage de OpenCode Go.
- Guarda la API key en macOS Keychain.
- Muestra uso rolling, weekly y monthly.
- Actualiza automáticamente cada 15 minutos.
- Incluye tests básicos del modelo y un script para generar un `.app`.
- El bundle actual se construye para Apple Silicon (`arm64`).

## Backlog priorizado

### P0: calidad y seguridad

- Añadir tests deterministas para `UsageAPIClient` con una sesión HTTP inyectable.
- Cubrir respuestas `401`, errores de red, JSON inválido y campos ausentes.
- Validar que los porcentajes estén dentro de `0...100` antes de renderizarlos.
- Evitar tareas de refresh duplicadas y cancelar correctamente el ciclo al cerrar la app.
- Añadir soporte de accesibilidad: labels descriptivos, navegación por teclado y contraste.
- Revisar el texto de configuración para usar consistentemente español o inglés.

### P1: experiencia de uso

- Añadir preferencias para el intervalo de actualización.
- Mostrar claramente la hora de la última actualización y el estado offline.
- Añadir una opción para borrar la API key del Keychain desde la interfaz.
- Añadir notificaciones configurables al superar 70%, 85% y 90%.
- Permitir elegir qué métrica aparece en la barra de menú.
- Añadir icono de aplicación y estados visuales para loading/error.

### P2: datos y compatibilidad

- Guardar snapshots locales de usage sin guardar la API key ni respuestas sensibles.
- Mostrar histórico de consumo con una gráfica simple.
- Detectar y documentar cambios del endpoint de OpenCode Go.
- Generar binarios `arm64` y `x86_64`, o un bundle universal.
- Añadir configuración de región, timezone y formato de fecha si el endpoint lo requiere.

### P3: distribución

- Crear un proyecto Xcode o un flujo de archive reproducible si SwiftPM no cubre el
  empaquetado necesario.
- Firmar la aplicación con Developer ID.
- Notarizar el `.app` y distribuirlo como `.dmg` o `.zip`.
- Automatizar releases y checksums en GitHub Actions.
- Evaluar Homebrew Cask únicamente cuando exista una release estable firmada.

## Orden recomendado de implementación

1. Tests del cliente HTTP y validación del modelo.
2. Correcciones de ciclo de vida y refresh concurrente.
3. Accesibilidad, icono y estados de error.
4. Preferencias y notificaciones.
5. Compatibilidad Intel y bundle universal.
6. CI, firma, notarización y releases.

## Criterios para una release estable

- `swift test` pasa sin acceso a internet.
- `swift build -c release` pasa en CI.
- Las respuestas reales y simuladas del endpoint están cubiertas.
- La API key nunca aparece en logs, archivos de configuración, screenshots de CI ni
  artefactos de release.
- La aplicación informa de errores de autenticación y red sin cerrarse.
- El `.app` se puede abrir desde Finder y muestra correctamente el identificador de
  bundle.
- Existe una guía de instalación y desinstalación para usuarios no técnicos.

## Plan para GitHub Open Source

### 1. Preparar el repositorio

- Añadir y revisar `AGENTS.md`.
- Añadir licencia. MIT es la opción simple para este proyecto, salvo que se prefiera
  otra licencia por motivos de marca o distribución.
- Añadir `CONTRIBUTING.md` con setup, comandos de validación y proceso de PR.
- Añadir `CODE_OF_CONDUCT.md` y `SECURITY.md` con el canal para reportar vulnerabilidades.
- Añadir `CHANGELOG.md` y definir versionado semántico desde `0.1.0`.
- Revisar el repositorio completo para eliminar API keys, tokens, cookies y artefactos.

### 2. Configurar GitHub

- Crear un repositorio público, preferiblemente con el nombre `opencode-go-widget`.
- Añadir descripción, topics (`swift`, `macos`, `menubar`, `opencode`) y URL del proyecto.
- Configurar la rama por defecto como `main`.
- Activar Issues y Discussions solo si se van a mantener.
- Añadir una plantilla de bug y otra de feature request.
- Activar Dependabot si se incorporan dependencias externas.
- Proteger `main` exigiendo CI verde antes de hacer merge.

### 3. Añadir CI antes de publicar

Crear `.github/workflows/ci.yml` que ejecute en macOS:

```bash
swift test
swift build -c release
```

El workflow no debe llamar al endpoint real ni requerir una API key. Las pruebas HTTP
deben usar respuestas mock o una sesión URLProtocol controlada por los tests.

### 4. Primera publicación

- Crear un commit inicial limpio con licencia y documentación.
- Crear el tag `v0.1.0` solo cuando CI esté verde.
- Publicar una release con instrucciones de instalación y limitaciones conocidas.
- No incluir la API key ni un `.app` sin firmar como si fuera una distribución confiable.
- Documentar que el usuario configura su propia API key en Keychain.

### 5. Releases posteriores

- Usar tags `vMAJOR.MINOR.PATCH`.
- Mantener `CHANGELOG.md` actualizado.
- Generar artefactos con nombres que indiquen arquitectura.
- Publicar checksums SHA-256.
- Añadir firma y notarización antes de recomendar descargas directas.

## Decisiones que requieren confirmación

- Licencia final: MIT, Apache-2.0 u otra.
- Idioma principal de la interfaz y documentación.
- Nombre y propietario del repositorio GitHub.
- Si se publicará solo el código o también binarios precompilados.
- Umbrales y frecuencia de notificaciones.
- Compatibilidad mínima definitiva de macOS e Intel.
