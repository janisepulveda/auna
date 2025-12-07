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
    %% Fase 1: Inicio y Permisos
    A((Descarga App)) --> B[Abre App]
    B --> C{Pide Permisos<br>Redes}
    
    %% Ramas Permiso Redes (CORREGIDO: Loop de reintento)
    C -- No --> D[Pantalla: Imposible<br>Muestra razón]
    D -- Reintentar --> C 
    
    C -- Sí --> E{Pide Permisos<br>Notificaciones}

    %% Ramas Permiso Notificaciones (Loop de reintento)
    E -- No --> F[Pantalla: Imposible<br>Muestra importancia]
    F -- Reintentar --> E

    E -- Sí --> G{¿Tiene Cuenta?}

    %% Fase 2: Cuenta
    G -- No --> H[Pantalla: Crear Cuenta]
    G -- Sí --> I[Pantalla: Continuar/Login]

    %% Fase 3: Navegación Manual
    H --> J[Inicio:<br>Flores Cerradas]
    I --> J
    J --> K[Usuario va a Ajustes]
    K --> L[Usuario prende Amuleto]
    L --> M[Presionar botón 'Conectar']

    %% Fase 4: Loop de Conexión
    M --> N{¿Se conecta?}
    N -- No --> M
    N -- Sí --> O((Listo para usar))

    %% Estilos
    style D fill:#ffcccc,stroke:#ff0000,stroke-width:2px
    style F fill:#ffcccc,stroke:#ff0000,stroke-width:2px
    style O fill:#ccffcc,stroke:#00ff00,stroke-width:2px
```

## 3. Flujo de Registro de Episodio de Dolor

Este diagrama muestra cómo la aplicación registra un episodio de dolor cuando el usuario presiona el amuleto, incluso si la app está en segundo plano.
```mermaid
flowchart LR
    %% --- ESTILOS ---
    classDef user fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    classDef app fill:#e3f2fd,stroke:#1565c0,stroke-width:2px;
    classDef system fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px;
    classDef physical fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,stroke-dasharray: 5 5;

    %% --- DEFINICIÓN DE CARRILES ---
    %% Definimos los carriles pero SIN forzar posiciones internas complejas
    
    subgraph UserLayer [1. Usuario]
        direction LR
        style UserLayer fill:none,stroke:none
        Pain(Siente Dolor):::user
        Press(Presiona Amuleto):::user
        Decide{¿Detalles?}:::user
        Save(Guardar):::user
    end

    subgraph UILayer [2. Interfaz]
        direction LR
        style UILayer fill:none,stroke:none
        Notif[Notificación]:::app
        Screen[Pantalla Detalles]:::app
        Feedback[Feedback Final]:::app
    end

    subgraph SysLayer [3. Sistema / Hardware]
        direction LR
        style SysLayer fill:none,stroke:none
        Signal((Señal BT)):::physical
        AutoSave[Auto-Guardado Hora]:::system
        UpdateDB[Guardado Full]:::system
        EndBasic((Fin Básico)):::system
    end

    %% --- CONEXIONES DIRECTAS (El orden importa) ---

    %% Paso 1: Inicio Físico
    Pain --> Press
    Press -.-> Signal

    %% Paso 2: Proceso Invisible
    Signal --> AutoSave
    AutoSave --> Notif

    %% Paso 3: Decisión
    Notif --> Decide
    
    %% Camino Corto (No)
    Decide -- Ahora no --> EndBasic

    %% Camino Largo (Sí)
    Decide -- Sí, editar --> Screen
    Screen --> Save
    Save --> UpdateDB
    UpdateDB --> Feedback
```
## 4. Flujo de registro manual

Este diagrama muestra cómo el usuario registra un episodio de dolor de forma manual en caso de no tener el amuleto.

```mermaid
flowchart LR
    %% --- ESTILOS ---
    classDef user fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    classDef app fill:#e3f2fd,stroke:#1565c0,stroke-width:2px;
    classDef action fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    classDef error fill:#ffebee,stroke:#c62828,stroke-width:1px;

    %% --- CARRIL SUPERIOR: SISTEMA ---
    subgraph SystemLayer [ ]
        direction LR
        style SystemLayer fill:none,stroke:none
        
        Home((Home)):::app
        FormScreen[Pantalla: Detalle]:::app
        Validate{Datos validos?}:::app
        Feedback[Registro Exitoso]:::app
        Update[Actualizar Jardin]:::app
        Error[Error: Faltan datos]:::error
    end

    %% --- CARRIL INFERIOR: USUARIO ---
    subgraph UserLayer [ ]
        direction LR
        style UserLayer fill:none,stroke:none
        
        Start(Inicio: Presiona +):::user
        PressSave(Presiona Guardar):::action
        
        %% GRUPO DE INPUTS (Compacto)
        subgraph Inputs [Llenar Datos]
            direction TB
            style Inputs fill:none,stroke:#ccc,stroke-dasharray: 5 5
            I1(Intensidad):::user
            I2(Tiempo):::user
            I3(Notas):::user
        end
    end

    %% --- CONEXIONES ---

    %% 1. Inicio
    Home --> Start
    Start --> FormScreen
    FormScreen -.-> Inputs

    %% 2. Acción
    Inputs --> PressSave
    PressSave --> Validate

    %% 3. Validación (El núcleo)
    Validate -- Sí --> Feedback
    Validate -- No --> Error
    
    %% Loop de error corto (Clave para que no se desordene)
    Error --> FormScreen

    %% 4. Cierre
    Feedback --> Update --> Home

    %% --- EL TRUCO DE COMPACTACIÓN (ALINEACIÓN) ---
    %% Esto fuerza que los elementos queden uno encima del otro
    
    Start ~~~ FormScreen
    Inputs ~~~ Validate
    PressSave ~~~ Error
```
## 5. Flujo de Visualización y Exportación (Reporte Médico)

Este diagrama muestra cómo el usuario transforma su experiencia subjetiva (el jardín) en un reporte clínico objetivo para su médico.

```mermaid
flowchart LR
    %% --- ESTILOS ---
    classDef user fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    classDef app fill:#e3f2fd,stroke:#1565c0,stroke-width:2px;
    classDef doc fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px;
    classDef error fill:#ffebee,stroke:#c62828,stroke-width:1px;

    %% --- CARRIL 1: USUARIO ---
    subgraph UserLayer [Acciones del Usuario]
        direction LR
        style UserLayer fill:none,stroke:none
        
        Filter(Filtra Fechas):::user
        PressExport(Presiona Exportar):::user
        Share(Comparte PDF):::user
    end

    %% --- CARRIL 2: SISTEMA ---
    subgraph SystemLayer [Procesamiento]
        direction LR
        style SystemLayer fill:none,stroke:none
        
        CheckData{Hay datos?}:::app
        GenPDF[Generar Reporte]:::doc
        Error[Alerta: Sin registros]:::error
        Preview[Vista Previa]:::app
    end

    %% --- CONEXIONES ---

    %% 1. Inicio
    Filter --> PressExport
    PressExport --> CheckData
    
    %% 2. La Decisión (Bifurcación)
    CheckData -- Si --> GenPDF
    CheckData -- No --> Error
    
    %% 3. El Loop (Rompe la linealidad)
    Error --> Filter

    %% 4. Éxito
    GenPDF --> Preview
    Preview --> Share
    Share --> Doctor((Enviar a Medico)):::doc

    %% --- ALINEACIÓN COMPACTA ---
    %% Alineamos la decisión justo debajo de la acción para ahorrar espacio
    PressExport ~~~ CheckData
    Share ~~~ Preview
```


