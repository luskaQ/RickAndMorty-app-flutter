# Nome do aplicativo: Rick and Morty App

# Integrantes
Lucas Ferreira Polidorio e Pedro Henrique de Oliveira Ribas

# Objetivo
Fornecer um local de consultas sobre dados da série Rick and Morty.

# Tecnologias utilizadas
Flutter e Firebase

# Bibliotecas utilizadas
- cupertino_icons: ^1.0.8
- http: ^1.6.0
- flutter_launcher_icons: ^0.14.4
- splash_master: ^1.0.0+1
- firebase_core: ^5.1.0
- firebase_auth: ^7.0.1
- cloud_firestore: ^7.1.0
- image_picker: ^1.2.4
- sqflite: ^2.4.2
- path: ^1.9.1
- table_calendar: ^3.2.0
- geolocator: ^14.0.0
- lottie: ^3.7.0

# Instruções para executar
Após clonar este repositório, tendo a versão 3.48.0-0.5.pre do FLutter ou equivalente instalada, no diretório do projeto, rode:\
    ```
    flutter pub get
    ```\
    ```
    flutter run
    ```\
    e escolha o dispositivo que você quer rodar.

# Funcionalidades implementadas
- Sincronização de banco de dados local com Firebase (Offline first);
- Tema do aplicativo padronizado usando theme.dart;
- Geolocalização;
- Seleção de data utilizando Table Calendar;
- Componentes padronizados reutilizáveis;
- Autenticação utilizando Firebase Auth;
- CRUD do perfil do usuário;
- Consumo da API de dados de Rick and Morty;
- Seleção de imagem utilizando Image Picker;
- Animações utilizando Lottie.