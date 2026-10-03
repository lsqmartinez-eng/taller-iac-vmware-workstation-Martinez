@echo off
setlocal EnableDelayedExpansion

:: --------------------------------------------------------
:: 1. VALORES POR DEFECTO
:: --------------------------------------------------------
set "VM_NAME="
set "VM_DIR=%USERPROFILE%\Documents\Virtual Machines"
set "VM_ISO="
set "VM_CPUS=2"
set "VM_MEM=2048"
set "VM_DISK=20"
set "VM_NET=nat"
set "START_VM=0"
set "DRY_RUN=0"
set "FORCE=0"

:: --------------------------------------------------------
:: 2. LECTURA DE PARÁMETROS (Como se vio en clase pero con nombres)
:: --------------------------------------------------------
:parse_args
if "%~1"=="" goto validate_args
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="--name" ( set "VM_NAME=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--dir" ( set "VM_DIR=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--iso" ( set "VM_ISO=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--cpus" ( set "VM_CPUS=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--mem" ( set "VM_MEM=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--disk" ( set "VM_DISK=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--net" ( set "VM_NET=%~2" & shift & shift & goto parse_args )
if /i "%~1"=="--start" ( set "START_VM=1" & shift & goto parse_args )
if /i "%~1"=="--dry-run" ( set "DRY_RUN=1" & shift & goto parse_args )
if /i "%~1"=="--force" ( set "FORCE=1" & shift & goto parse_args )
echo Error: Parametro desconocido %~1
exit /b 2

:: --------------------------------------------------------
:: 3. VALIDACIÓN DE ENTRADAS (Pruebas T3, T4, T5, T6)
:: --------------------------------------------------------
:validate_args
if "%VM_NAME%"=="" ( echo Error: Falta el parametro --name & exit /b 2 )

:: Validar que el nombre no tenga caracteres raros (T3)
echo %VM_NAME%| findstr /R "^[a-zA-Z0-9._-]*$" >nul
if errorlevel 1 ( echo Error: Nombre invalido. & exit /b 2 )

:: Validar CPUs y RAM mayor a 0 (T4)
if %VM_CPUS% leq 0 ( echo Error: CPUs debe ser mayor a 0. & exit /b 2 )
if %VM_MEM% leq 0 ( echo Error: Memoria debe ser mayor a 0. & exit /b 2 )
if %VM_DISK% leq 0 ( echo Error: Disco debe ser mayor a 0. & exit /b 2 )

:: Validar red (T5)
if /i not "%VM_NET%"=="nat" if /i not "%VM_NET%"=="bridged" if /i not "%VM_NET%"=="hostonly" (
    echo Error: Modo de red invalido. Use nat, bridged o hostonly.
    exit /b 2
)

:: Validar ISO si se indico (T6)
if not "%VM_ISO%"=="" (
    if not exist "%VM_ISO%" ( echo Error: El archivo ISO no existe. & exit /b 2 )
)

:: --------------------------------------------------------
:: 4. LÓGICA DE IDEMPOTENCIA Y CARPETAS (T8 y T9)
:: --------------------------------------------------------
set "TARGET_DIR=%VM_DIR%\%VM_NAME%"

if exist "%TARGET_DIR%" (
    if "%FORCE%"=="0" (
        echo Error: La maquina virtual ya existe. Use --force para sobrescribir.
        exit /b 1
    ) else (
        echo [INFO] Recreando la VM %VM_NAME%...
        if "%DRY_RUN%"=="0" rmdir /S /Q "%TARGET_DIR%"
    )
)

:: --------------------------------------------------------
:: 5. SIMULACIÓN (DRY-RUN - T2)
:: --------------------------------------------------------
if "%DRY_RUN%"=="1" (
    echo [SIMULACION] Se creara la carpeta: %TARGET_DIR%
    echo [SIMULACION] Se creara el disco duro de %VM_DISK% GB en %TARGET_DIR%\disk.vmdk
    echo [SIMULACION] Se creara el archivo %VM_NAME%.vmx con %VM_CPUS% vCPUs, %VM_MEM% MB RAM y red %VM_NET%
    if not "%VM_ISO%"=="" echo [SIMULACION] Se montara la ISO: %VM_ISO%
    if "%START_VM%"=="1" echo [SIMULACION] Se encendera la VM al finalizar.
    exit /b 0
)

:: --------------------------------------------------------
:: 6. CREACIÓN DE CARPETA Y ARCHIVOS (Como lo hizo el profe en clase)
:: --------------------------------------------------------
echo [INFO] Creando carpeta de la VM...
mkdir "%TARGET_DIR%"
cd /d "%TARGET_DIR%"

echo [INFO] Generando archivo de configuracion .vmx...
:: Utilizamos echo con redirección como enseño el profesor
echo .encoding = "UTF-8" > "%VM_NAME%.vmx"
echo config.version = "8" >> "%VM_NAME%.vmx"
echo virtualHW.version = "16" >> "%VM_NAME%.vmx"
echo guestOS = "ubuntu-64" >> "%VM_NAME%.vmx"
echo displayName = "%VM_NAME%" >> "%VM_NAME%.vmx"
echo memsize = "%VM_MEM%" >> "%VM_NAME%.vmx"
echo numvcpus = "%VM_CPUS%" >> "%VM_NAME%.vmx"
echo ethernet0.present = "TRUE" >> "%VM_NAME%.vmx"
echo ethernet0.connectionType = "%VM_NET%" >> "%VM_NAME%.vmx"
echo scsi0.present = "TRUE" >> "%VM_NAME%.vmx"
echo scsi0.virtualDev = "lsilogic" >> "%VM_NAME%.vmx"
echo scsi0:0.present = "TRUE" >> "%VM_NAME%.vmx"
echo scsi0:0.fileName = "disk.vmdk" >> "%VM_NAME%.vmx"

if not "%VM_ISO%"=="" (
    echo ide1:0.present = "TRUE" >> "%VM_NAME%.vmx"
    echo ide1:0.deviceType = "cdrom-image" >> "%VM_NAME%.vmx"
    echo ide1:0.fileName = "%VM_ISO%" >> "%VM_NAME%.vmx"
)

:: --------------------------------------------------------
:: 7. CREACIÓN DEL DISCO DURO
:: --------------------------------------------------------
echo [INFO] Creando disco virtual de %VM_DISK% GB...
vmware-vdiskmanager -c -t 0 -s %VM_DISK%GB -a lsilogic disk.vmdk
if errorlevel 1 ( echo Error al crear el disco. & exit /b 1 )

:: --------------------------------------------------------
:: 8. ENCENDER LA VM Y VALIDAR
:: --------------------------------------------------------
echo [INFO] Maquina %VM_NAME% creada exitosamente.

if "%START_VM%"=="1" (
    echo [INFO] Encendiendo la maquina virtual...
    vmrun -T ws start "%TARGET_DIR%\%VM_NAME%.vmx"
    if errorlevel 1 ( echo Error al encender la VM. & exit /b 1 )
    echo [INFO] La VM esta en ejecucion.
)

exit /b 0

:: --------------------------------------------------------
:: MENÚ DE AYUDA (T1)
:: --------------------------------------------------------
:show_help
echo Uso: crear-vm.cmd --name NOMBRE [Opciones]
echo.
echo Parametros obligatorios:
echo   --name NOMBRE   Nombre de la VM.
echo.
echo Opciones:
echo   --dir RUTA      Carpeta base (Por defecto: Mis Documentos\Virtual Machines)
echo   --iso RUTA      Ruta a la imagen ISO de instalacion
echo   --cpus N        Numero de vCPUs (Por defecto: 2)
echo   --mem MB        Memoria RAM en MB (Por defecto: 2048)
echo   --disk GB       Tamano de disco en GB (Por defecto: 20)
echo   --net MODO      nat, bridged o hostonly (Por defecto: nat)
echo   --start         Enciende la VM al terminar
echo   --dry-run       Simula el proceso sin crear nada
echo   --force         Sobrescribe la VM si ya existe
exit /b 0