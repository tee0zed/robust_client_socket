# RobustClientSocket

⚠️ Not Production Tested (yet)

HTTP client for secure inter-service communications with automatic authorization token generation.

## 📋 Table of Contents

- [Security Features](#security-features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [HTTP Methods](#http-methods)
- [Error Handling](#error-handling)
- [SSL/TLS Settings](#ssltls-settings)

## 🔒 Security Features

RobustClientSocket provides secure communication between microservices:

### 1. Automatic Tokenization
- **On-the-fly Token Generation**: Each request automatically gets a new token
- **Timestamps**: Tokens contain UTC timestamp for replay attack protection
- **One-time Tokens**: Each request uses a unique token

### 2. RSA Encryption
- **RSA-2048 Minimum**: Automatic key size validation
- **PKCS1_OAEP_PADDING**: Secure padding for attack protection
- **Key Validation**: Public key correctness verification during configuration

### 3. TLS/SSL Protection
- **TLS 1.2+**: Modern encryption protocols
- **Certificate Verification**: VERIFY_PEER mode for production
- **Configurable Cipher Suites**: ECDHE support for forward secrecy
- **HTTPS Enforcement**: Mandatory HTTPS usage in production

### 4. Header Protection
- **Custom Headers**: Configurable header name for token
- **User-Agent Identification**: Client versioning
- **Content-Type Control**: Automatic headers for JSON

### 5. Timeout Attack Protection
- **Connection Timeout**: Configurable connection timeout (default: 5s)
- **Request Timeout**: Configurable request timeout (default: 10s)
- **Hang Protection**: Automatic interruption of long requests

### 6. Multi-service Architecture
- **Keychain Management**: Separate keys for each service
- **Automatic Client Generation**: Dynamic class creation for services
- **Configuration Isolation**: Independent settings for each service

## 📦 Installation

Add to Gemfile:

```ruby
gem 'robust_client_socket'
```

Then execute:

```bash
bundle install
```

## ⚙️ Configuration

Create file `config/initializers/robust_client_socket.rb`:

```ruby
RobustClientSocket.configure do |c|
  # REQUIRED: Current service (client) name
  # Must match allowed_services on server
  c.client_name = 'core'
  
  # OPTIONAL: Header name for token (default: 'Secure-Token')
  c.header_name = 'Secure-Token'
  
  # KEYCHAIN: Configuration for each target service
  
  # Basic configuration (without SSL validation)
  c.payments = {
    base_uri: 'http://localhost:3001',
    public_key: ENV['PAYMENTS_PUBLIC_KEY']
  }
  
  # Production configuration with SSL
  c.notifications = {
    base_uri: 'https://notifications.example.com',
    public_key: ENV['NOTIFICATIONS_PUBLIC_KEY'],
    ssl_verify: true,  # Enable SSL certificate verification
    timeout: 15,       # Request timeout (seconds)
    open_timeout: 5    # Connection timeout (seconds)
  }
  
  # Configuration with custom cipher suites
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

# Load configuration and create clients
RobustClientSocket.load!
```

### Service Configuration Options

| Parameter | Type | Required | Default | Description |
|----------|-----|--------------|---------|----------|
| `base_uri` | String | ✅ | - | Target service URL |
| `public_key` | String | ✅ | - | Service RSA public key |
| `ssl_verify` | Boolean | ❌ | false | Enable SSL certificate verification |
| `timeout` | Integer | ❌ | 10 | Request timeout (seconds) |
| `open_timeout` | Integer | ❌ | 5 | Connection timeout (seconds) |
| `ciphers` | Array/String | ❌ | See below | TLS cipher suites |

**Default cipher suites:**
```
ECDHE-RSA-AES128-GCM-SHA256
ECDHE-RSA-AES256-GCM-SHA384
ECDHE-ECDSA-AES128-GCM-SHA256
ECDHE-ECDSA-AES256-GCM-SHA384
```

## 🚀 Usage

### Automatic Client Generation

After `RobustClientSocket.load!` classes are automatically created for each represented service:

```ruby
# Configuration
c.payments = { base_uri: '...', public_key: '...' }
c.notifications = { base_uri: '...', public_key: '...' }
c.user_management = { base_uri: '...', public_key: '...' }

# After load! classes are available:
RobustClientSocket::Payments          # payments -> Payments
RobustClientSocket::Notifications     # notifications -> Notifications
RobustClientSocket::UserManagement    # user_management -> UserManagement
```

### Basic Usage

```ruby
# GET request
response = RobustClientSocket::Payments.get('/api/v1/transactions')

if response.success?
  transactions = response.parsed_response
  puts "Transactions received: #{transactions.count}"
else
  puts "Error: #{response.code} - #{response.message}"
end

# POST request with body
response = RobustClientSocket::Notifications.post(
  '/api/v1/send',
  body: {
    user_id: 123,
    message: 'Hello World',
    type: 'email'
  }.to_json
)

# PUT request
response = RobustClientSocket::UserManagement.put(
  '/api/v1/users/123',
  body: { name: 'John Doe' }.to_json
)

# DELETE request
response = RobustClientSocket::Payments.delete('/api/v1/transactions/456')

# PATCH request
response = RobustClientSocket::UserManagement.patch(
  '/api/v1/users/123',
  body: { status: 'active' }.to_json
)
```

### Query Parameters

```ruby
# GET with query parameters
response = RobustClientSocket::Payments.get(
  '/api/v1/transactions',
  query: {
    status: 'completed',
    date_from: '2024-01-01',
    limit: 100
  }
)

# Automatically converted to:
# /api/v1/transactions?status=completed&date_from=2024-01-01&limit=100
```

### Custom Headers

```ruby
# Adding additional headers
response = RobustClientSocket::Payments.get(
  '/api/v1/transactions',
  headers: {
    'X-Request-ID' => SecureRandom.uuid,
    'X-User-ID' => current_user.id.to_s
  }
)

# Secure-Token header is added automatically!
```

## 🌐 HTTP Methods

All standard HTTPpartry methods:

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

### Request Options

```ruby
{
  body: '{"key": "value"}',           # Request body (String or Hash)
  query: { param: 'value' },          # Query parameters (Hash)
  headers: { 'X-Custom': 'value' },   # Additional headers (Hash)
  timeout: 30,                        # Override request timeout
  open_timeout: 10                    # Override connection timeout
}
```

## ❌ Error Handling

### Exception Types

| Exception | Reason | Action |
|-----------|---------|----------|
| `InsecureConnectionError` | HTTP used in production with `ssl_verify: true` | Use HTTPS |
| `InvalidCredentialsError` | Missing `base_uri` or `public_key` | Check configuration |
| `SecurityError` | Key less than 2048 bits or invalid | Use correct RSA-2048+ key |
| `OpenSSL::PKey::RSAError` | Encryption error | Check public key format |
| `Timeout::Error` | Timeout exceeded | Increase timeout or check service |
| `SocketError` | Service unavailable | Check base_uri and network |

### Error Handling

```ruby
begin
  response = RobustClientSocket::Payments.post(
    '/api/v1/charge',
    body: { amount: 1000 }.to_json
  )
  
  if response.success?
    # Success
  elsif response.code == 401
    # Authorization problem
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
  # Use HTTPS in production
  
rescue Timeout::Error => e
  Rails.logger.error("Request timeout: #{e.message}")
  # Retry or timeout handling
  
rescue SocketError => e
  Rails.logger.error("Service unavailable: #{e.message}")
  # Service unavailable
  
rescue SecurityError => e
  Rails.logger.error("Security error: #{e.message}")
  # Problem with keys or encryption
  
rescue StandardError => e
  Rails.logger.error("Unexpected error: #{e.class} - #{e.message}")
end
```

## 🔐 SSL/TLS Settings

### Production Configuration

```ruby
RobustClientSocket.configure do |c|
  c.client_name = 'core'
  
  c.payments = {
    base_uri: 'https://payments.example.com',
    public_key: ENV['PAYMENTS_PUBLIC_KEY'],
    
    # Enable SSL validation
    ssl_verify: true,
    
    # TLS 1.2+ with secure ciphers
    ciphers: %w[
      ECDHE-RSA-AES128-GCM-SHA256
      ECDHE-RSA-AES256-GCM-SHA384
    ]
  }
end
```

### 2. Synchronization with Server

```ruby
# Client
RobustClientSocket.configure do |c|
  c.client_name = 'core'  # ← Important: current service name
  
  c.payments = {
    base_uri: 'https://payments.example.com',
    public_key: '-----BEGIN PUBLIC KEY-----...'  # PAYMENTS service public key
  }
end

# Server (payments)
RobustServerSocket.configure do |c|
  c.allowed_services = %w[core]  # ← Must contain 'core'
  c.private_key = '-----BEGIN PRIVATE KEY-----...'  # Private pair to public key above
end
```

## 🤝 Integration with RobustServerSocket

### Full Setup Example

**Service A (client):**
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

**Service B (server):**
```ruby
# config/initializers/robust_server_socket.rb
RobustServerSocket.configure do |c|
  c.allowed_services = %w[service_a]  # Allow service_a
  c.private_key = ENV['SERVICE_B_PRIVATE_KEY']
  c.token_expiration_time = 3
  c.redis_url = ENV['REDIS_URL']
  c.redis_pass = ENV['REDIS_PASSWORD']
end

RobustServerSocket.load!
```

**Key Pair Generation:**
```bash
# Generate private key (for Service B)
openssl genrsa -out service_b_private.pem 2048

# Generate public key (for Service A)
openssl rsa -in service_b_private.pem -pubout -out service_b_public.pem

# Add to environment variables
# Service A: SERVICE_B_PUBLIC_KEY=$(cat service_b_public.pem)
# Service B: SERVICE_B_PRIVATE_KEY=$(cat service_b_private.pem)
```

## 📚 Additional Resources

- [BENCHMARK_ANALYSIS.md](../BENCHMARK_ANALYSIS.md)
- [RobustServerSocket documentation](../robust_server_socket/README.ru.md)
- [HTTParty documentation](https://github.com/jnunemaker/httparty)
- [OpenSSL Ruby documentation](https://ruby-doc.org/stdlib/libdoc/openssl/rdoc/OpenSSL.html)

## 📝 License

See [LICENSE.txt](LICENSE.txt) file

## 🐛 Bugs and Suggestions

Report issues through your repository's issue tracker.
