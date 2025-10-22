# Diagramas de Flujo de la App AUNA

Este documento describe los flujos de usuario principales de **AUNA**, una aplicación diseñada para registrar episodios de dolor mediante un dispositivo complementario (amuleto). Los diagramas a continuación ilustran los pasos desde el inicio de la app hasta la gestión de episodios de dolor.

---
## 1. Sistema de Organización y Navegación

Todas las pantallas que existen y cómo están conectadas entre sí.
```mermaid
graph LR
    %% El Nivel 0 son las pantallas de Onboarding
    A("Inicio") --> B{¿Usuario tiene sesión?};
    B -- No --> C["Flujo de Onboarding <br> (Login / Crear Cuenta)"];
    B -- Sí --> D["Navegación Principal (Tab Bar)"];

    %% El Nivel 1 son las 3 pestañas principales que mostraste
    D --> E["Home (Flores de Loto)"];
    D --> F["Historial (Calendario)"];
    D --> G["Ajustes (Perfil)"];

    %% El Nivel 2 son las pantallas que salen de las principales
    
    %% Desde Home
    E -- "Presiona '+'" --> H["Pantalla: Detalle de Crisis"];
    %% Vuelve a Home
    H -- "Guardar" --> E;

    %% Desde Historial
    F -- "Selecciona un día" --> I["Pantalla: Detalles del Día"];
    %% Vuelve al Calendario
    I --> F;

    %% Desde Ajustes
    G --> J["Pantalla: Conectar Amuleto"];
    G --> K["Pantalla: Contacto de Emergencia"];
    G --> L["Pantalla: Exportar Historial"];
```
## 2. Flujo de Onboarding

Este flujo muestra el proceso que sigue un usuario desde que descarga la aplicación hasta que conecta su amuleto y llega a la pantalla de inicio (Home).

```mermaid
graph LR
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

## 3. Flujo de Registro de Episodio de Dolor

Este diagrama muestra cómo la aplicación registra un episodio de dolor cuando el usuario presiona el amuleto, incluso si la app está en segundo plano.
```mermaid
flowchart LR
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
## 4. Flujo de registro manual

Este diagrama muestra cómo el usuario registra un episodio de dolor de forma manual en caso de no tener el amuleto.
```mermaid
flowchart LR
    A("Inicio: Pantalla Home") --> B@{ label: "Usuario presiona 'Registrar Episodio de Dolor'" }
    B --> C@{ label: "Abre Pantalla 'Detalle del Episodio'" }
    C --> D@{ label: "Usuario ajusta 'Intensidad'" }
    D --> E@{ label: "Usuario ajusta 'Fecha y Hora'" }
    E --> F@{ label: "Usuario ingresa 'Duración'" }
    F --> G@{ label: "Usuario escribe 'Notas'" }
    G --> H@{ label: "Usuario presiona 'Guardar Registro'" }
    H --> I("Fin: App regresa a Home")

    B@{ shape: rect}
    C@{ shape: rect}
    D@{ shape: rect}
    E@{ shape: rect}
    F@{ shape: rect}
    G@{ shape: rect}
    H@{ shape: rect}
```
Consideraciones Adicionales

Flujos Pendientes: Sería útil diagramar otros flujos como la visualización del historial de dolor, la configuración de perfil y la gestión de permisos.

Manejo de Errores: Se deben considerar los casos de error, como la falla en la conexión Bluetooth o la pérdida de señal del amuleto.
