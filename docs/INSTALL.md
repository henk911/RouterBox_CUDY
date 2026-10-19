# Публикация и установка CudyRoute

## Публикация репозитория

Целевой репозиторий: `henk911/RouterBox_CUDY`. Для публикации в другом аккаунте создайте пустой репозиторий и измените origin. Загрузите подготовленную Git-историю:

```sh
git clone CudyRoute-WR3000U.bundle CudyRoute-WR3000U
cd CudyRoute-WR3000U
git remote set-url origin https://github.com/henk911/RouterBox_CUDY.git
git push -u origin main
```

Первый успешный workflow в `main` репозитория `henk911/RouterBox_CUDY` сам публикует `v0.4.0`. Для ручного выпуска в другом репозитории создайте тег:

```sh
git tag v0.4.0
git push origin v0.4.0
```

Во вкладке Actions дождитесь успешной сборки и публикации. Исходники ZIP также можно распаковать и загрузить обычным Git, но Git bundle сохраняет историю оригинала и изменения порта.

## SSH

Скачайте `cudyroute-wr3000u-0.4.0.tar.gz` из Releases и передайте на роутер, как описано в README. Выполните сначала `sh ./install.sh --check`, затем `sh ./install.sh --flash`.

После публикации релиза можно скачать и запустить bootstrap с компьютера роутера:

```sh
wget -O /tmp/cudyroute-bootstrap.sh https://raw.githubusercontent.com/henk911/RouterBox_CUDY/main/bootstrap.sh
sh /tmp/cudyroute-bootstrap.sh
```

Проверьте успешную загрузку перед запуском. Bootstrap загружает последний опубликованный комплект, проверяет его SHA256 и запускает подписанную установку. Для установки без запуска используйте `sh /tmp/cudyroute-bootstrap.sh --disabled`.

## Режимы

- `--check`: только проверка комплекта и ресурсов.
- `--flash`: приложение и сжатое ядро во flash; на новой установке VPN выключен.
- `--disabled`: пакеты без запуска и автозапуска; настройки прежней установки не сбрасываются.
- `--app-only`: только приложение; затем настройте в интерфейсе HTTPS-загрузку gzip ядра в RAM с SHA256 и распакованным размером из manifest.json. После перезагрузки URL должен быть доступен без VPN.

Для установки нужны интернет и рабочие репозитории именно вашей прошивки. При ошибке kernel dependency не используйте принудительную установку — сначала исправьте источники пакетов.

## Резервная копия и диагностика

С компьютера:

```sh
ssh root@192.168.1.1 'tar -czf - /etc/cudyroute /etc/config/cudyroute' > cudyroute-backup.tar.gz
```

Копия содержит параметры серверов; храните её приватно.

На роутере:

```sh
logread -e cudyroute
free -m
df -h /overlay /tmp
```

На физическом устройстве нужно проверить импорт своей подписки, DNS, TUN/auto_redirect, IPv6 и прохождение UDP. Linux-тесты сборки этого не подтверждают.
