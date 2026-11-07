# Ручная установка без Rojo

1. Создайте или откройте Roblox place.
2. В `ReplicatedStorage` создайте папку `BonkShared` и скопируйте туда содержимое `src/shared` как ModuleScript.
3. В `ServerScriptService` создайте папку `BonkServer` и скопируйте туда `src/server`, сохранив подпапки `Config`, `Data`, `Services`.
4. Установите `Main.server.luau` как Script с именем `Main` внутри `BonkServer`; остальные `.luau` оставьте ModuleScript, кроме entry point.
5. В `StarterPlayer > StarterPlayerScripts` создайте папку `BonkClient`, скопируйте `src/client`, а `Main.client.luau` установите как LocalScript `Main`.
6. На папке `BonkServer` создайте Attribute `StudioMock` типа Boolean. Для локальной Studio-проверки поставьте `true`; перед публикацией обязательно `false`.
7. Запустите Play. Сервер создаст `Workspace/BonkWorld` и `ReplicatedStorage/BonkRemotes` сам.

Не создавайте вручную кнопки, remotes, зоны или детали карты. Если `BonkWorld` уже существует и не имеет `BonkOwned=true` или имеет другую версию, сервер остановится вместо перезаписи чужого дерева.

Перед публикацией включите Studio API access только в тестовой копии, проверьте DataStore с `StudioMock=false` в отдельном place и настройте реальные ID покупок только в опубликованной конфигурации.
