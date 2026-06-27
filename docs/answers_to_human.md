```text
◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆
◆░░░░░░░░░░░░░░◆
◇▒▒▒▒▒▒▒▒▒▒▒▒▒▒◇
◆   ответ на   ◆
◇  вопрос: 16  ◇
◆▒▒▒▒▒▒▒▒▒▒▒▒▒▒◆
◇░░░░░░░░░░░░░░◇
◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇
```

```text
Готово: добавил текущий запрос как шаг 16 в docs/steps_human.md, обновил AGENTS.md и создал docs/answers_to_human.md. Теперь правило проекта требует для каждого запроса сохранять не только текст вопроса в steps_human, но и финальный ответ в answers_to_human с тем же номером вопроса.

Для answers_to_human.md использую разделитель высотой 8 строк и шириной 16 символов. Так как фраза "ответ на вопрос: N" целиком не помещается в ширину 16, она записывается в центре двумя строками: "ответ на" и "вопрос: N".
```

```text
◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆
◆░░░░░░░░░░░░░░◆
◇▒▒▒▒▒▒▒▒▒▒▒▒▒▒◇
◆   ответ на   ◆
◇  вопрос: 17  ◇
◆▒▒▒▒▒▒▒▒▒▒▒▒▒▒◆
◇░░░░░░░░░░░░░░◇
◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇
```

```text
Готово: переформатировал docs/steps_human.md так, что настоящие символьные разделители шагов теперь высотой 8 строк. Проверка показывает, что все блоки вида "◆    шаг N    ◆" имеют высоту 8.

По подписи: да, в целом логика верная, но точнее это не только сертификат. С платным Apple Developer Program Xcode использует Apple Development certificate и development provisioning profile для твоего Bundle ID и зарегистрированного iPhone. Приложение подписывается сертификатом, а provisioning profile встраивается в app bundle; iPhone при запуске проверяет подпись, профиль, entitlement-ы, Bundle ID, регистрацию устройства и сроки действия.

То есть причина, почему приложение не должно умереть через 7 дней, в том, что это уже не free/personal provisioning на 7 дней, а нормальная подпись через developer team. Но приложение все равно может перестать запускаться, когда истечет provisioning profile/сертификат или membership; тогда нужно пересобрать/переподписать приложение новым профилем.

Источники Apple: https://developer.apple.com/help/account/certificates/certificates-overview, https://developer.apple.com/help/account/provisioning-profiles/create-a-development-provisioning-profile, https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles
```

```text
◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆
◆░░░░░░░░░░░░░░◆
◇▒▒▒▒▒▒▒▒▒▒▒▒▒▒◇
◆   ответ на   ◆
◇  вопрос: 18  ◇
◆▒▒▒▒▒▒▒▒▒▒▒▒▒▒◆
◇░░░░░░░░░░░░░░◇
◆◇◆◇◆◇◆◇◆◇◆◇◆◇◆◇
```

```text
Да. На платном Apple Developer Program срок больше, чем 7 дней у free/personal provisioning.

Но точная модель такая: приложение не получает какой-то "вечный сертификат". Xcode подписывает app Apple Development certificate и встраивает development provisioning profile. iPhone проверяет подпись, профиль, Bundle ID, entitlements, регистрацию устройства и сроки действия. Пока профиль/сертификат действуют и membership активен, приложение не должно отвалиться через 7 дней.

Для dev-установки через Xcode это обычно срок жизни development provisioning profile, а не 7 дней. Когда срок истечет, Xcode при следующей сборке/запуске сможет обновить managed profile, и приложение надо будет пересобрать/переустановить. Для более "пользовательского" варианта без ручного переподписывания нужен App Store или TestFlight, но TestFlight builds тоже имеют свой срок жизни.

Источники Apple: https://developer.apple.com/help/account/certificates/certificates-overview, https://developer.apple.com/help/account/provisioning-profiles/create-a-development-provisioning-profile, https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles
```
