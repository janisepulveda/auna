# Diagramas de Flujo de la App AUNA

Este documento describe los flujos de usuario principales de **AUNA**, una aplicación diseñada para registrar episodios de dolor mediante un dispositivo complementario (amuleto). Los diagramas a continuación ilustran los pasos desde el inicio de la app hasta la gestión de episodios de dolor.

---
## 1. Sistema de Organización y Navegación

Todas las pantallas que existen y cómo están conectadas entre sí.
```mermaid
flowchart LR
    %% --- ESTILOS ---
    classDef main fill:#fff,stroke:#333,stroke-width:1px;
    classDef action fill:#e3f2fd,stroke:#1565c0,stroke-width:2px;
    classDef physical fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,stroke-dasharray: 5 5;
    classDef alert fill:#ffebee,stroke:#c62828,stroke-width:2px;
    classDef feedback fill:#dcfce7,stroke:#166534,stroke-width:2px;

    %% --- COLUMNA 1: ENTRADAS ---
    subgraph Inputs [Entradas]
        direction TB
        style Inputs fill:transparent,stroke:none
        Amuleto(Amuleto Físico):::physical
        Inicio((Inicio))
    end

    %% --- COLUMNA 2: NAVEGACIÓN (El Menú) ---
    subgraph TabBar [Navegación Principal]
        direction TB
        %% EL TRUCO: Usamos '---' para pegarlos físicamente
        Home[Home: Jardín]:::main
        Home --- Historial[Historial]:::main
        Historial --- Ajustes[Ajustes]:::main
    end

    %% --- COLUMNA 3: ACCIONES ---
    CrisisForm[Detalle de Crisis]:::action
    VerDia[Ver Día]:::main
    
    %% --- CONEXIONES ---
    
    %% Flujo Inicio
    Inicio --> Check{¿Sesión?}
    Check -- No --> Onboard[Login] --> Home
    Check -- Sí --> Home

    %% Flujo Amuleto
    Amuleto -.->|Presiona Botón| CrisisForm

    %% Flujo Home
    Home -->|Botón +| CrisisForm
    CrisisForm --> Guardar{Guardado}:::feedback
    Guardar --> Home

    %% Flujo Historial
    Historial --> VerDia -->|Editar| CrisisForm

    %% Flujo Ajustes
    Ajustes --> Conectar[Conectar amuleto]:::main
    Ajustes --> Exportar[Exportar historial]:::main
    Ajustes --> SOS[Contacto de emergencia]:::alert
    
    SOS -.-> Call((Mensaje SMS))
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
