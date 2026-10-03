# Automatización de Máquinas Virtuales en VMware Workstation (IaC)

Este repositorio contiene un script `.cmd` que automatiza la creación y configuración de máquinas virtuales en VMware Workstation utilizando comandos nativos de Windows, aplicando los principios fundamentales de la Infraestructura como Código (IaC).

## Requisitos Previos
* Sistema Operativo: Windows.
* VMware Workstation Pro instalado.
* Tener la ruta de instalación de VMware (ej. `C:\Program Files (x86)\VMware\VMware Workstation`) agregada a la variable de entorno `PATH`.

## Uso del Script
El script `crear-vm.cmd` se ejecuta desde la línea de comandos de Windows (cmd) y acepta múltiples parámetros para parametrizar el hardware virtual.

### Parámetro Obligatorio
* `--name NOMBRE`: Asigna el nombre de la máquina y su carpeta contenedora.

### Parámetros Opcionales
* `--cpus N`: Número de procesadores virtuales (Por defecto: 2).
* `--mem MB`: Memoria RAM en MB (Por defecto: 2048).
* `--disk GB`: Tamaño del disco duro virtual (Por defecto: 20).
* `--net MODO`: Modo de red, soporta nat, bridged o hostonly (Por defecto: nat).
* `--iso RUTA`: Monta una imagen ISO para la instalación del sistema operativo.
* `--dry-run`: Simula el proceso en la consola sin escribir ni modificar archivos.
* `--force`: Permite recrear una máquina virtual sobrescribiendo la existente.
* `--start`: Enciende la máquina automáticamente tras su creación.

### Ejemplo de Ejecución
crear-vm.cmd --name servidor_web --cpus 4 --mem 4096 --disk 30 --net bridged --start
