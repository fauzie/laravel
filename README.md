# Laravel :heart: Docker

Your laravel project root must be mounted to `/app/current`

- Nginx
- PHP 8.2
- PHP all default extensions
- PHP imagick
- PHP redis
- PHP ssh2
- PHP memcached (memcached server included)
- NodeJs 20 + npm + yarn

#### Environment
- `DOMAIN` = nginx domain name
- `USERNAME` = server user name, default `app`
- `USERGROUP` = server user group, default `app`
- `USE_HORIZON` = set to any value to enable horizon supervisor
- `USE_REVERB` = set to any value to enable reverb server
- `OPCACHE_ENABLE` = enable or disable php opcache, default `Off`
- `PHP_DISPLAY_ERRORS` = enable or disable php error on runtime, Default `On`
- `PHP_MEMORY_LIMIT` = php memory limit, default `512M`

---
Code by [fauzie](https://github.com/fauzie) with :heart: and :coffee:
