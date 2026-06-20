# PHP 8.1 + Apache для застосунку AgroCraft
FROM php:8.1-apache

# Розширення, які використовує код: mysqli (БД) + openssl (шифрування паролів — вже в ядрі).
# mod_php працює лише з MPM prefork. Деякі базові образи мають увімкнений ще й
# mpm_event/mpm_worker одночасно -> помилка "More than one MPM loaded".
# Тому: видаляємо лише mpm_event та mpm_worker (але НЕ mpm_prefork),
# вимикаємо їх через a2dismod, потім вмикаємо лише prefork, і ОДРАЗУ
# перевіряємо в білді, що увімкнено рівно один MPM (інакше білд падає).
RUN docker-php-ext-install mysqli \
  && rm -f /etc/apache2/mods-available/mpm_event.load \
           /etc/apache2/mods-available/mpm_event.conf \
           /etc/apache2/mods-available/mpm_worker.load \
           /etc/apache2/mods-available/mpm_worker.conf \
           /etc/apache2/mods-enabled/mpm_event.load \
           /etc/apache2/mods-enabled/mpm_event.conf \
           /etc/apache2/mods-enabled/mpm_worker.load \
           /etc/apache2/mods-enabled/mpm_worker.conf \
  && a2dismod mpm_event mpm_worker 2>/dev/null || true \
  && a2enmod mpm_prefork rewrite \
  && echo "Enabled MPM .load files:" \
  && find /etc/apache2/mods-enabled/ -name "mpm_*.load" \
  && test "$(find /etc/apache2/mods-enabled/ -name 'mpm_*.load' | wc -l)" = "1"

# Код застосунку лежить у папці src/ — копіюємо її як корінь сайту
COPY src/ /var/www/html/

# Railway передає порт через змінну $PORT — Apache має слухати саме його.
# At build time we write ${PORT} as a placeholder into the config files.
# At runtime, sed expands ${PORT} to the actual value before Apache starts.
ENV PORT=80
RUN sed -i 's/Listen 80/Listen ${PORT}/' /etc/apache2/ports.conf \
  && sed -i 's/:80>/:${PORT}>/' /etc/apache2/sites-available/000-default.conf \
  && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
  && cp /etc/apache2/ports.conf /etc/apache2/ports.conf.template \
  && cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.template

CMD ["bash", "-c", "rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_event.conf /etc/apache2/mods-enabled/mpm_worker.load /etc/apache2/mods-enabled/mpm_worker.conf && sed \"s/\\${PORT}/$PORT/g\" /etc/apache2/ports.conf.template > /etc/apache2/ports.conf && sed \"s/\\${PORT}/$PORT/g\" /etc/apache2/sites-available/000-default.conf.template > /etc/apache2/sites-available/000-default.conf && exec apache2-foreground"]
