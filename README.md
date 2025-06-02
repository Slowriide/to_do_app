
Aplicación de notas y tareas desarrollada en Flutter, utilizando Riverpod para la gestión de estado. Permite crear, editar y eliminar tareas de manera sencilla y eficiente.

## 🚀 Características

- 📋 Crear, editar y eliminar tareas.
- ✅ Marcar tareas como completadas.
- 🔄 Gestión de estado con Riverpod.
- 💾 Persistencia local de datos.
- 📱 Interfaz amigable y responsiva.

## 🧰 Tecnologías utilizadas

- [Flutter](https://flutter.dev/)
- [Riverpod](https://riverpod.dev/)
- [Isar](https://isar.dev/)

## 📦 Instalación

1. Clona el repositorio:

   ```bash
   git clone https://github.com/Slowriide/to_do_app.git
   cd to_do_app
   flutter pub get
   flutter run

## 📁 Estructura del proyecto

lib/
├── main.dart              # Punto de entrada
├── common/                # Estilos, constantes, widgets generales
├── core/                  # Configuraciones globales, navegación, inyección de dependencias
├── data/                  # Fuentes de datos (API, DB, storage) y DTOs
├── domain/                # Entidades, casos de uso, repositorios abstractos
├── presentation/          # UI (widgets, screens), controladores de estado