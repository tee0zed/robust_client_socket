# RobustClientSocket

⚠️ Not Production Tested (yet)

HTTP-клиент для защищённых межсервисных коммуникаций с автоматической генерацией токенов авторизации.

## 📋 Содержание

- [Функции безопасности](#функции-безопасности)
- [Установка](#установка)
- [Конфигурация](#конфигурация)
- [Использование](#использование)
- [Методы HTTP](#методы-http)
- [Обработка ошибок](#обработка-ошибок)
- [SSL/TLS настройки](#ssltls-настройки)

## 🔒 Функции безопасности

RobustClientSocket обеспечивает защищённую коммуникацию между микросервисами:

### 1. Автоматическая токенизация
- **Генерация токенов на лету**: Каждый запрос автоматически получает новый токен
- **Временные метки**: Токены содержат UTC timestamp для защиты от replay attacks
- **Одноразовые токены**: Каждый запрос использует уникальный токен

### 2. RSA шифрование
- **RSA-2048 минимум**: Автоматическая валидация размера ключа
- **PKCS1_OAEP_PADDING**: Безопасный padding для защиты от атак
- **Валидация ключей**: Проверка корректности публичных ключей при конфигурации

### 3. TLS/SSL защита
- **TLS 1.2+**: Современные протоколы шифрования
- **Проверка сертификатов**: VERIFY_PEER режим для production
- **Настраиваемые cipher suites**: Поддержка ECDHE для forward secrecy
- **HTTPS enforcement**: Обязательное использование HTTPS в production

### 4. Защита заголовков
- **Кастомные заголовки**: Настраиваемое имя заголовка для токена
- **User-Agent идентификация**: Версионирование клиента
- **Content-Type контроль**: Автоматические заголовки для JSON

### 5. Защита от timeout атак
- **Connection timeout**: Настраиваемый таймаут подключения (default: 5s)
- **Request timeout**: Настраиваемый таймаут запроса (default: 10s)
- **Защита от зависания**: Автоматическое прерывание долгих запросов

### 6. Мультисервисная архитектура
- **Keychain управление**: Отдельные ключи для каждого сервиса
- **Автоматическая генерация клиентов**: Динамическое создание классов для сервисов
- **Изоляция конфигураций**: Независимые настройки для каждого сервиса

## 📦 Установка

Добавьте в Gemfile:

```ruby
gem 'robust_client_socket'
```

Затем выполните:

```bash
bundle install
```

## ⚙️ Конфигурация

Создайте файл `config/initializers/robust_client_socket.rb`:

```ruby
RobustClientSocket.configure do |c|
  # ОБЯЗАТЕЛЬНО: Имя текущего сервиса (клиента)
  # Должно совпадать с allowed_services на сервере
  c.client_name = 'core'
  
  # ОПЦИОНАЛЬНО: Имя заголовка для токена (default: 'Secure-Token')
  c.header_name = 'Secure-Token'
  
  # KEYCHAIN: Конфигурация для каждого целевого сервиса
  
  # Базовая конфигурация (без SSL валидации)
  c.payments = {
    base_uri: 'http://localhost:3001',
    public_key: ENV['PAYMENTS_PUBLIC_KEY']
  }
  
  # Production конфигурация с SSL
  c.notifications = {
    base_uri: 'https://notifications.example.com',
    public_key: ENV['NOTIFICATIONS_PUBLIC_KEY'],
    ssl_verify: true,  # Включить проверку SSL сертификатов
    timeout: 15,       # Таймаут запроса (секунды)
    open_timeout: 5    # Таймаут подключения (секунды)
  }
  
  # Конфигурация с кастомными cipher suites
  c.core = {
    base_uri: 'https://core.example.com',
    public_key: ENV['CORE_PUBLIC_KEY'],
    ssl_verify: true,
    ciphers: %w[
      ECDHE-RSA-AES128-GCM-SHA256
      ECDHE-RSA-AES256-GCM-SHA384
      ECDHE-ECDSA-AES128-GCM-SHA256
      ECDHE-ECDSA-AES256-GCM-SHA384
    ]
  }
end

# Загрузка конфигурации и создание клиентов
RobustClientSocket.load!
```

### Опции конфигурации сервиса

| Параметр | Тип | Обязательный | Default | Описание |
|----------|-----|--------------|---------|----------|
| `base_uri` | String | ✅ | - | URL целевого сервиса |
| `public_key` | String | ✅ | - | Публичный RSA ключ сервиса |
| `ssl_verify` | Boolean | ❌ | false | Включить проверку SSL сертификатов |
| `timeout` | Integer | ❌ | 10 | Таймаут запроса (секунды) |
| `open_timeout` | Integer | ❌ | 5 | Таймаут подключения (секунды) |
| `ciphers` | Array/String | ❌ | См. ниже | TLS cipher suites |

**Default cipher suites:**
```
ECDHE-RSA-AES128-GCM-SHA256
ECDHE-RSA-AES256-GCM-SHA384
ECDHE-ECDSA-AES128-GCM-SHA256
ECDHE-ECDSA-AES256-GCM-SHA384
```

## 🚀 Использование

### Автоматическая генерация клиентов

После `RobustClientSocket.load!` автоматически создаются классы для каждого объявленного сервиса:

```ruby
# Конфигурация
c.payments = { base_uri: '...', public_key: '...' }
c.notifications = { base_uri: '...', public_key: '...' }
c.user_management = { base_uri: '...', public_key: '...' }

# После load! доступны классы:
RobustClientSocket::Payments          # payments -> Payments
RobustClientSocket::Notifications     # notifications -> Notifications
RobustClientSocket::UserManagement    # user_management -> UserManagement
```

### Базовое использование

```ruby
# GET запрос
response = RobustClientSocket::Payments.get('/api/v1/transactions')

if response.success?
  transactions = response.parsed_response
  puts "Получено транзакций: #{transactions.count}"
else
  puts "Ошибка: #{response.code} - #{response.message}"
end

# POST запрос с телом
response = RobustClientSocket::Notifications.post(
  '/api/v1/send',
  body: {
    user_id: 123,
    message: 'Hello World',
    type: 'email'
  }.to_json
)

# PUT запрос
response = RobustClientSocket::UserManagement.put(
  '/api/v1/users/123',
  body: { name: 'John Doe' }.to_json
)

# DELETE запрос
response = RobustClientSocket::Payments.delete('/api/v1/transactions/456')

# PATCH запрос
response = RobustClientSocket::UserManagement.patch(
  '/api/v1/users/123',
  body: { status: 'active' }.to_json
)
```

### Query параметры

```ruby
# GET с query параметрами
response = RobustClientSocket::Payments.get(
  '/api/v1/transactions',
  query: {
    status: 'completed',
    date_from: '2024-01-01',
    limit: 100
  }
)

# Автоматически преобразуется в:
# /api/v1/transactions?status=completed&date_from=2024-01-01&limit=100
```

### Кастомные заголовки

```ruby
# Добавление дополнительных заголовков
response = RobustClientSocket::Payments.get(
  '/api/v1/transactions',
  headers: {
    'X-Request-ID' => SecureRandom.uuid,
    'X-User-ID' => current_user.id.to_s
  }
)

# Secure-Token заголовок добавляется автоматически!
```

## 🌐 Методы HTTP

Все стандартные HTTPpartry методы:

### GET
```ruby
RobustClientSocket::ServiceName.get(path, options = {})
```

### POST
```ruby
RobustClientSocket::ServiceName.post(path, options = {})
```

### PUT
```ruby
RobustClientSocket::ServiceName.put(path, options = {})
```

### DELETE
```ruby
RobustClientSocket::ServiceName.delete(path, options = {})
```

### PATCH
```ruby
RobustClientSocket::ServiceName.patch(path, options = {})
```

### HEAD
```ruby
RobustClientSocket::ServiceName.head(path, options = {})
```

### OPTIONS
```ruby
RobustClientSocket::ServiceName.options(path, options = {})
```

### Опции запроса

```ruby
{
  body: { "key": "value" },           # Тело запроса (Hash)
  query: { param: 'value' },          # Query параметры (Hash)
  headers: { 'X-Custom': 'value' },   # Дополнительные заголовки (Hash)
  timeout: 30,                        # Переопределить таймаут запроса
  open_timeout: 10                    # Переопределить таймаут подключения
}
```

## ❌ Обработка ошибок

### Типы исключений

| Исключение | Причина | Действие |
|-----------|---------|----------|
| `InsecureConnectionError` | HTTP используется в production с `ssl_verify: true` | Используйте HTTPS |
| `InvalidCredentialsError` | Отсутствуют `base_uri` или `public_key` | Проверьте конфигурацию |
| `SecurityError` | Ключ меньше 2048 бит или невалиден | Используйте корректный RSA-2048+ ключ |
| `OpenSSL::PKey::RSAError` | Ошибка шифрования | Проверьте формат публичного ключа |
| `Timeout::Error` | Превышен таймаут | Увеличьте timeout или проверьте сервис |
| `SocketError` | Сервис недоступен | Проверьте base_uri и сеть |

### Обработка ошибок

```ruby
begin
  response = RobustClientSocket::Payments.post(
    '/api/v1/charge',
    body: { amount: 1000 }.to_json
  )
  
  if response.success?
    # Успешно
  elsif response.code == 401
    # Проблема авторизации
    Rails.logger.error("Auth failed: token may be rejected by server")
  elsif response.code == 422
    # Validation error
    errors = response.parsed_response['errors']
  elsif response.code >= 500
    # Server error
    Rails.logger.error("Server error: #{response.code}")
  end
  
rescue RobustClientSocket::HTTP::Client::InsecureConnectionError => e
  Rails.logger.error("Insecure connection: #{e.message}")
  # Используйте HTTPS в production
  
rescue Timeout::Error => e
  Rails.logger.error("Request timeout: #{e.message}")
  # Retry или обработка таймаута
  
rescue SocketError => e
  Rails.logger.error("Service unavailable: #{e.message}")
  # Сервис недоступен
  
rescue SecurityError => e
  Rails.logger.error("Security error: #{e.message}")
  # Проблема с ключами или шифрованием
  
rescue StandardError => e
  Rails.logger.error("Unexpected error: #{e.class} - #{e.message}")
end
```

## 🔐 SSL/TLS настройки

### Production конфигурация

```ruby
RobustClientSocket.configure do |c|
  c.client_name = 'core'
  
  c.payments = {
    base_uri: 'https://payments.example.com',
    public_key: ENV['PAYMENTS_PUBLIC_KEY'],
    
    # Включить SSL валидацию
    ssl_verify: true,
    
    # TLS 1.2+ с безопасными ciphers
    ciphers: %w[
      ECDHE-RSA-AES128-GCM-SHA256
      ECDHE-RSA-AES256-GCM-SHA384
    ]
  }
end
```

### 2. Синхронизация с сервером

```ruby
# Клиент
RobustClientSocket.configure do |c|
  c.client_name = 'core'  # ← Важно: имя текущего сервиса
  
  c.payments = {
    base_uri: 'https://payments.example.com',
    public_key: '-----BEGIN PUBLIC KEY-----...'  # Публичный ключ PAYMENTS сервиса
  }
end

# Сервер (payments)
RobustServerSocket.configure do |c|
  c.allowed_services = %w[core]  # ← Должно содержать 'core'
  c.private_key = '-----BEGIN PRIVATE KEY-----...'  # Приватная пара к публичному ключу выше
end
```

## 🤝 Интеграция с RobustServerSocket

### Полный пример настройки

**Сервис A (client):**
```ruby
# config/initializers/robust_client_socket.rb
RobustClientSocket.configure do |c|
  c.client_name = 'service_a'
  
  c.service_b = {
    base_uri: ENV['SERVICE_B_URL'],
    public_key: ENV['SERVICE_B_PUBLIC_KEY'],
    ssl_verify: Rails.env.production?
  }
end

RobustClientSocket.load!
```

**Сервис B (server):**
```ruby
# config/initializers/robust_server_socket.rb
RobustServerSocket.configure do |c|
  c.allowed_services = %w[service_a]  # Разрешить service_a
  c.private_key = ENV['SERVICE_B_PRIVATE_KEY']
  c.token_expiration_time = 3
  c.redis_url = ENV['REDIS_URL']
  c.redis_pass = ENV['REDIS_PASSWORD']
end

RobustServerSocket.load!
```

**Генерация пары ключей:**
```bash
# Генерация приватного ключа (для Service B)
openssl genrsa -out service_b_private.pem 2048

# Генерация публичного ключа (для Service A)
openssl rsa -in service_b_private.pem -pubout -out service_b_public.pem

# Добавить в переменные окружения
# Service A: SERVICE_B_PUBLIC_KEY=$(cat service_b_public.pem)
# Service B: SERVICE_B_PRIVATE_KEY=$(cat service_b_private.pem)
```

## 📚 Дополнительные ресурсы

- [RobustServerSocket documentation](../robust_server_socket/README.ru.md)
- [HTTParty documentation](https://github.com/jnunemaker/httparty)
- [OpenSSL Ruby documentation](https://ruby-doc.org/stdlib/libdoc/openssl/rdoc/OpenSSL.html)

## 📝 Лицензия

См. файл [LICENSE.txt](LICENSE.txt)

## 🐛 Баги и предложения

Сообщайте о проблемах через issue tracker вашего репозитория.
