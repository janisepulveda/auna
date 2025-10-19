# Diagramas de Flujo de la App AUNA

Este documento contiene los flujos de usuario principales para la aplicación AUNA, que ayuda a registrar episodios de dolor a través de un dispositivo complementario (amuleto).

1. Flujo de Onboarding

Este flujo describe el proceso desde que un usuario descarga la app por primera vez hasta que conecta su amuleto y llega a la pantalla de inicio (Home), listo para usar.
```mermaid
graph TD
    A("Inicio: Tienda de Apps") --> B["Usuario descarga AUNA"];
    B --> C["Abre la App"];
    C --> D{"Pantalla de Bienvenida <br> (Login / Crear Cuenta)"};
    D -- "Inicia Sesión" --> E["Pantalla de Login"];
    E --> F("Usuario ingresa sus datos");
    F --> G["App solicita Permisos <br> (Bluetooth, Notificaciones)"];
    G --> H("Usuario acepta permisos");
    H --> I["Pantalla: 'Conecta tu amuleto'"];
    I --> J(("Acción Física: <br> Usuario presiona el amuleto"));
    J --> K{"App detecta señal"};
    K --> L["Pantalla de Éxito <br> '¡Amuleto Conectado!'"];
    L --> M("Fin: Usuario en Pantalla Home");
```

2. Flujo de Registro de Episodio de Dolor

Este diagrama muestra cómo la aplicación registra un episodio de dolor cuando el usuario presiona el amuleto, incluso si la app está en segundo plano.
```mermaid
flowchart TD
    A(("Contexto: <br> Usuario siente dolor")) --> B(("Acción Física: <br> Usuario presiona el amuleto"))
    B --> C{"Amuleto envía señal <br> (Bluetooth)"}
    C --> D{"App recibe la señal <br> (Incluso en segundo plano)"}
    D --> E["Sistema muestra Notificación / Pop-up <br> '¿Quieres añadir detalles?'"]
    E --> F{"Usuario decide..."}
    F -- "Sí, añadir" --> G["Se abre App en Pantalla de Detalles <br> (Intensidad, Duración, Notas)"]
    G --> H("Usuario presiona 'Guardar'")
    H --> I("Fin: Registro completo guardado en Historial")
    F -- "Ahora no" --> J["Notificación se cierra"]
    J --> K("Fin: Registro básico <br> (hora/fecha) guardado")
```

Consideraciones Adicionales

Flujos Pendientes: Sería útil diagramar otros flujos como la visualización del historial de dolor, la configuración de perfil y la gestión de permisos.

Manejo de Errores: Se deben considerar los casos de error, como la falla en la conexión Bluetooth o la pérdida de señal del amuleto.
