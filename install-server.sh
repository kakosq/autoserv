#!/bin/bash
#авто установщик сервера майнкрафт. Автор vk.com/quebyee

set -euo pipefail

# Проверка прав суперпользователя
if [[ $EUID -ne 0 ]]; then
  echo "Скрипт должен быть запущен с правами суперпользователя" >&2
  exit 1
fi

#создание папки
echo "Введите имя папки которую хотите создать:"
read folder_name

mkdir "$folder_name"
cd "$folder_name"

# Запрос на выбор репозитория
read -rp $'Выберите версию (1 или 2):\n1. 1.1.5\n2. 1.19.X\n' answer

case $answer in
  1)
    repository="https://github.com/dixsin/linux-server.git";;
  2)
    repository="https://github.com/kakosq/server.git";;
  *)
    echo "Некорректный выбор репозитория" >&2
    exit 1
    ;;
esac

# Проверка наличия git и установка, если не установлен
check_git() {
  if ! command -v git &> /dev/null; then
    read -rp $'Git не установлен. Хотите установить git? (y/n)\n' answer
    if [[ $answer =~ ^[Yy]$ ]]; then
      if ! command -v apt &> /dev/null; then
        echo "APT не установлен"
        exit 1
      fi
      if ! apt-get install git -y; then
        echo "Ошибка установки git"
        exit 1
      fi
    else
      echo "Git не установлен. Выбрано прервать установку."
      exit 1
    fi
  fi
}

# Клонирование репозитория
clone_repository() {
  check_git # проверка наличия git и установка, если не установлен
  echo "Копирование обязательных файлов сервера (Ядро, Библиотеки)..."
  if ! git clone "$repository" .; then
      echo "Ошибка клонирования репозитория $repository" >&2
      exit 1
  fi
}

# Функция выдачи прав скриптам
set_script_permissions() {
  echo "Выдача прав скриптам"
  if ! chmod -R 777 .; then
    echo "Ошибка выдачи прав скриптам" >&2
    exit 1
  fi
  echo "Выдача прав завершена успешно"
}

# Функция запуска сервера
start_server() {
  echo "Запуск сервера"
  if ! ./start.sh; then
    echo "Ошибка запуска сервера" >&2
    exit 1
  fi
  echo "Сервер запущен успешно"
}

# Обновление пакетов
echo "Обновление пакетов"
if ! apt-get update && apt-get upgrade -y; then
  echo "Ошибка обновления пакетов" >&2
  exit 1
fi
echo "Обновление пакетов завершено успешно"
clear

# Установка screen
read -rp $'Хотите установить screen? (y/n)\n' answer
if [[ $answer =~ ^[Nn]$ ]]; then
  echo "Установка screen пропущена"
else
  if ! command -v apt &> /dev/null; then
    echo "APT не установлен"
    exit 1
  fi

  if ! apt-get install screen -y; then
    echo "Ошбика установки screen"
    exit 1
  fi
  echo "Screen успешно установлен"
fi


# Клонирование репозитория
clone_repository

# Выдача прав скриптам
set_script_permissions

# Запуск сервера
start_server

# Выход
exit 0
