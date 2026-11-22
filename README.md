# TimeRepeat (proyecto inicial iOS)

Este es un proyecto SwiftUI inicial para compilar una app personal de iPhone.

## Funciones incluidas
- Intervalo configurable en horas, minutos y segundos.
- Número de avisos configurable (1 a 64).
- Notificaciones locales con sonido predeterminado.
- Cuenta atrás en primer plano.
- Pausar, continuar y cancelar.

## Importante
- Este proyecto todavía no es un archivo IPA. Sideloadly instala un IPA ya compilado; no compila el proyecto.
- Para generar el IPA hace falta Xcode en macOS o un servicio de compilación macOS en la nube.
- iOS limita las notificaciones locales pendientes por aplicación (habitualmente 64).
- iOS y el modo silencio/Enfoque pueden silenciar sonidos. Una app normal no puede garantizar sonido audible si el iPhone está en silencio.
- La pausa cancela avisos pendientes y la reanudación programa la secuencia restante; esta primera versión es un prototipo y debe probarse antes de confiar en ella para procesos críticos.
- El identificador de paquete es `com.timerepeat.personal`; se puede cambiar durante la firma/compilación.
