---
name: zadvizhka-editor
description: Набор инструкций для редактирования Flutter-проекта Zadvizhka (система водоподготовки)
---

# Навык: Редактирование Zadvizhka

Этот навык содержит инструкции для внесения изменений в проект "Задвижка — Моделирование системы водоподготовки".

## Основные файлы

### Модель данных (`lib/models/imitation_model.dart`)

| Поле | Тип | Описание |
|------|-----|----------|
| `_hEmk` | `double` | Уровень ёмкости (м³), по умолч. 1000 |
| `_hChem` | `double` | Уровень химцеха (м³), по умолч. 400 |
| `_qValve1` | `double` | Поток через З1 (т/ч), 0–300 |
| `_qValve2` | `double` | Поток через З2 (т/ч), 0–300 |
| `_qOut` | `double` | Подпитка на выходе (т/ч), 50–250 |
| `_randomQOut` | `bool` | Режим подпитки: случайный/фикс |
| `_running` | `bool` | Симуляция запущена |
| `_speedSlider` | `double` | Положение слайдера скорости (0..1) |

**Методы установки** (все с `clamp` и `notifyListeners`):
- `setQValve1(double q)` — установка З1
- `setQValve2(double q)` — установка З2
- `setQOut(double v)` — установка подпитки
- `setRandomQOut(bool v)` — переключение режима
- `setSpeed(double v)` — скорость
- `start()`, `stop()`, `reset()` — управление симуляцией

### UI (`lib/widgets/imitation_screen.dart`)

**Структура экрана:**
1. Заголовок + версия
2. `_buildControls()` — кнопки Пуск/Стоп/Сброс + слайдер скорости + время
3. `_buildFlowDiagram()` — схема потока (Row с узлами и стрелками)
4. Два бака (`_buildTank`) — Ёмкость и Химцех
5. `_buildVerticalSliders()` — вертикальные слайдеры

**Узлы схемы (`_buildFlowDiagram`):**
- `_flowNode(label, value, color)` — статический узел (Ввод, Ёмкость, Химцех, Выход)
- `_flowNodeEditable(label, value, percentage, color, step, onIncrease, onDecrease)` — узел с кнопками +/-
  - Кнопки — `IconButton` с `Icons.remove_circle_outline` / `Icons.add_circle_outline`, размер 16
  - Для подпитки (`isRandom`) кнопки отключаются серым цветом

**Вертикальные слайдеры (`_buildVerticalSliders`):**
- Три колонки: З1, З2, Подпитка
- Каждая содержит: `_verticalSlider(label, subtitle, hint, value, color, onChanged, ...)`
- value — нормализованное 0..1 (делением на `qInMax`)
- Содержит кнопки вверх/вниз (шаг 0.05 в нормализованных единицах)

## Типовые изменения

### Добавление нового элемента управления
1. Добавить поле в `ImitationModel`
2. Добавить setter с `clamp` и `notifyListeners`
3. Добавить UI-элемент в `ImitationScreen`
4. Убедиться, что `reset()` сбрасывает новое поле

### Синхронизация элементов управления
- Все элементы должны читать/писать одни и те же поля модели
- Кнопки +/- вызывают `setQValve1(qValve1 + 1)` и т.д.
- Слайдеры вызывают `setQValve1(v * qInMax)`
- Вертикальные слайдеры уже используют `_model.qValve1 / qInMax` как value

### Изменение размера кнопок
- `IconButton` — параметры `icon`, `constraints`, `padding`
- Для крупных кнопок: увеличить `size` в `Icon`, увеличить `minWidth`/`minHeight` в `constraints`

## Сборка и деплой

```powershell
flutter build web --base-href="/Zadvizhka/"
# Копирование в корень и docs
Copy-Item -Recurse -Force build/web/* .
Copy-Item -Recurse -Force build/web/* docs/
```

Проверка: `flutter analyze` перед коммитом.