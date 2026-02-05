# RobustClientSocket

A secure HTTP client library for service-to-service communication within a microservices architecture. Uses RSA public-key cryptography to authenticate requests with time-limited, one-time-use tokens.

[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7.7-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

## Overview

RobustClientSocket enables secure, authenticated HTTP communication between microservices using:

- **RSA-2048 Public Key Encryption**: Each request includes a token encrypted with the server's public key
- **Timestamped Tokens**: All tokens include UTC timestamps to prevent replay attacks
- **Automatic Token Generation**: Tokens are automatically created and attached to every request
- **HTTParty Integration**: Built on top of HTTParty for familiar HTTP client interface
- **HTTPS Enforcement**: Requires HTTPS in production environments
- **Configurable Timeouts**: Control connection and request timeout behavior

## Security Model

### How It Works

1. **Configuration**: Each service configured with target service's public RSA key
2. **Token Generation**: On each request, client generates token: `{client_name}_{timestamp}`
3. **Encryption**: Token encrypted with server's public key (RSA-2048 with OAEP padding)
4. **Base64 Encoding**: Encrypted token encoded to Base64 for HTTP transport
5. **Header Injection**: Token automatically added to request headers (default: `Secure-Token`)
6. **Server Validation**: Server decrypts token using private key and validates client name and timestamp

### Security Features

- **Minimum Key Size**: Enforces 2048-bit RSA keys minimum
- **TLS 1.2+**: Requires modern TLS with secure cipher suites
- **SSL Verification**: Enforces peer certificate verification in production
- **No Token Reuse**: Server tracks used tokens (requires `RobustServerSocket`)
- **Time-Limited**: Tokens expire after configured period
- **Public Key Only**: Client never has access to private keys

## Installation

Add to your Gemfile:

```ruby
gem 'robust_client_socket'
```

Or install directly:

```bash
gem install robust_client_socket
```

## Configuration

### Basic Setup

Create an initializer (e.g., `config/initializers/robust_client_socket.rb`):

```ruby
RobustClientSocket.configure do |config|
  # Client identification (must match allowed_services on server)
  config.client_name = 'mobile-api'
  
  # Header name for authentication token (default: 'Secure-Token')
  config.header_name = 'Secure-Token'
  
  # Configure services to connect to
  config.core = {
    base_uri: 'https://core.example.com',
    public_key: ENV['CORE_PUBLIC_KEY']  # Server's public RSA key
  }
  
  config.payment = {
    base_uri: 'https://payment.example.com',
    public_key: ENV['PAYMENT_PUBLIC_KEY']
  }
end

# Load the configured clients
RobustClientSocket.load!
```

### Configuration Options

#### Per-Service Options

```ruby
config.service_name = {
  base_uri: 'https://api.example.com',      # Required: Base URL
  public_key: '-----BEGIN PUBLIC KEY-----', # Required: RSA public key (PEM format)
  
  # Optional: SSL verification (default: true)
  ssl_verify: true,
  
  # Optional: Request timeout in seconds (default: 10)
  timeout: 15,
  
  # Optional: Connection timeout in seconds (default: 5)
  open_timeout: 8
}
```

#### Global Options

```ruby
config.client_name = 'my-service'    # Required: Service identifier
config.header_name = 'Custom-Auth'   # Optional: Header name (default: 'Secure-Token')
```

## Usage

### Making HTTP Requests

After configuration, services are available as class constants:

```ruby
# GET request
response = RobustClientSocket::Core.get('/api/v1/users')

# POST request with JSON body
response = RobustClientSocket::Core.post(
  '/api/v1/users',
  body: { user: { name: 'John Doe', email: 'john@example.com' } }
)

# PATCH request
response = RobustClientSocket::Payment.patch(
  '/api/v1/transactions/123',
  body: { status: 'completed' }
)

# DELETE request
response = RobustClientSocket::Core.delete('/api/v1/users/456')

# PUT request
response = RobustClientSocket::Core.put(
  '/api/v1/settings',
  body: { theme: 'dark' }
)
```

### Request Options

All HTTParty options are supported:

```ruby
RobustClientSocket::Core.get(
  '/api/v1/users',
  query: { page: 1, per_page: 20 },
  headers: { 'X-Custom-Header' => 'value' },
  timeout: 30
)

RobustClientSocket::Core.post(
  '/api/v1/data',
  body: { data: 'value' },
  headers: { 'Content-Type' => 'application/json' }
)
```

### Response Handling

Responses are standard HTTParty response objects:

```ruby
response = RobustClientSocket::Core.get('/api/v1/users/123')

# Status code
response.code        # => 200
response.success?    # => true

# Response body
response.body        # Raw body string
response.parsed_response  # Parsed JSON (if Content-Type is JSON)

# Headers
response.headers['content-type']  # => "application/json"

# Convenience methods
user = response['user']  # Direct hash access for JSON responses
```

### Error Handling

```ruby
begin
  response = RobustClientSocket::Core.get('/api/v1/protected')
  
  if response.success?
    puts "Success: #{response.parsed_response}"
  else
    puts "Error: #{response.code} - #{response.message}"
  end
rescue RobustClientSocket::HTTP::Client::InsecureConnectionError => e
  # HTTPS required in production
  Rails.logger.error "Security error: #{e.message}"
rescue RobustClientSocket::HTTP::Client::InvalidCredentialsError => e
  # Invalid configuration
  Rails.logger.error "Configuration error: #{e.message}"
rescue SecurityError => e
  # Encryption/key validation errors
  Rails.logger.error "Security error: #{e.message}"
rescue HTTParty::Error => e
  # Network/HTTP errors
  Rails.logger.error "HTTP error: #{e.message}"
end
```

## Advanced Usage

### Custom Message Encryption

For encrypting arbitrary messages (not just tokens):

```ruby
# Encrypt a message with timestamp
encrypted = RobustClientSocket::Core.encrypt_message("sensitive-data")
# Returns: Base64-encoded encrypted string of "sensitive-data_{timestamp}"

# Add timestamp to message without encryption
timestamped = RobustClientSocket::Core.message_with_timestamp("my-message")
# Returns: "my-message_{unix_timestamp}"
```

### Manual Configuration Validation

```ruby
# Check if configuration is valid
RobustClientSocket.configured?  # => true/false

# Check specific configuration details
RobustClientSocket.configuration.client_name
RobustClientSocket.configuration.services
```

## Key Management

### Generating Key Pairs

On the server (RobustServerSocket) side:

```ruby
require 'openssl'

# Generate 2048-bit RSA key pair
key = OpenSSL::PKey::RSA.new(2048)

# Private key (keep secret on server)
private_key = key.to_pem
File.write('private_key.pem', private_key)

# Public key (distribute to clients)
public_key = key.public_key.to_pem
File.write('public_key.pem', public_key)
```

### Key Rotation

To rotate keys:

1. Generate new key pair on server
2. Update server with new private key
3. Distribute new public key to clients
4. Update client configuration
5. Restart clients to load new public key

### Best Practices

- Store keys in environment variables or secure vaults (e.g., AWS Secrets Manager)
- Never commit keys to version control
- Use different keys per environment (dev/staging/prod)
- Rotate keys periodically (every 6-12 months)
- Use 2048-bit minimum (4096-bit for high-security environments)

## Environment-Specific Configuration

### Development

```ruby
RobustClientSocket.configure do |config|
  config.client_name = 'dev-api'
  
  # Allow HTTP in development (not recommended for production)
  config.local_service = {
    base_uri: 'http://localhost:3001',
    public_key: ENV['DEV_PUBLIC_KEY'],
    ssl_verify: false  # Disable SSL verification for self-signed certs
  }
end
```

### Production

```ruby
RobustClientSocket.configure do |config|
  config.client_name = 'production-api'
  
  # HTTPS enforced automatically in production
  config.core = {
    base_uri: 'https://core.example.com',
    public_key: ENV['CORE_PUBLIC_KEY'],
    timeout: 10,
    open_timeout: 5
  }
end
```

## Performance Considerations

### Connection Pooling

HTTParty handles connection pooling automatically. For heavy loads:

```ruby
# Configure persistent connections
config.service = {
  base_uri: 'https://api.example.com',
  public_key: ENV['PUBLIC_KEY'],
  timeout: 15,
  open_timeout: 5,
  persistent: true  # Reuse connections
}
```

### Caching RSA Keys

RSA keys are cached at the class level to avoid repeated key parsing:

```ruby
# Keys are loaded once during .init() and reused for all requests
# No need for manual caching
```

### Token Generation Overhead

Each request generates and encrypts a token. This adds ~1-2ms per request. For high-throughput services:

- Use connection pooling
- Keep timeout values reasonable
- Monitor encryption overhead in profiling

## Testing

### RSpec Examples

```ruby
RSpec.describe 'User API Client' do
  before do
    RobustClientSocket.configure do |config|
      config.client_name = 'test-client'
      config.api = {
        base_uri: 'https://api.test.com',
        public_key: test_public_key
      }
    end
    RobustClientSocket.load!
  end
  
  describe 'fetching users' do
    it 'returns user list' do
      stub_request(:get, "https://api.test.com/users")
        .with(headers: { 'Secure-Token' => /^[A-Za-z0-9+\/]+=*$/ })
        .to_return(status: 200, body: { users: [] }.to_json)
      
      response = RobustClientSocket::Api.get('/users')
      expect(response.success?).to be true
    end
  end
end
```

### WebMock Integration

```ruby
require 'webmock/rspec'

# Stub authenticated requests
stub_request(:post, "https://api.example.com/endpoint")
  .with(
    headers: {
      'Secure-Token' => /.+/,
      'Content-Type' => 'application/json'
    }
  )
  .to_return(status: 200, body: '{"success": true}')
```

## Troubleshooting

### Common Errors

#### InvalidCredentialsError

```
Missing keys: base_uri, public_key
```

**Solution**: Ensure all required configuration keys are provided:
- `base_uri` must be present and non-empty
- `public_key` must be present and non-empty

#### InsecureConnectionError

```
HTTPS required in production. Use https:// instead of http://example.com
```

**Solution**: Use HTTPS URLs in production environments. HTTP is only allowed in development.

#### SecurityError

```
RSA key size (1024 bits) below minimum (2048 bits)
```

**Solution**: Use RSA keys of at least 2048 bits. Generate new keys:

```ruby
OpenSSL::PKey::RSA.new(2048)
```

#### Encryption Failed

```
Encryption failed: data too large for key size
```

**Solution**: Tokens are small, but if encrypting custom messages, ensure data size < (key_size / 8) - 42 bytes.

### Debugging

Enable HTTParty debugging:

```ruby
RobustClientSocket::Core.debug_output $stdout

response = RobustClientSocket::Core.get('/endpoint')
# Prints request/response details to stdout
```

Check configuration:

```ruby
# Verify configuration loaded
puts RobustClientSocket.configured?
puts RobustClientSocket.configuration.client_name
puts RobustClientSocket.configuration.services.keys
```

## Architecture

### Components

```
RobustClientSocket
├── Configuration         # Configuration DSL and validation
├── HTTP::Client         # Base HTTP client with HTTParty
├── HTTP::Helpers        # Encryption and token generation
└── HTTP::HTTPartyOverrides  # Custom request handling
```

### Request Flow

```
1. Application calls RobustClientSocket::ServiceName.get('/path')
   ↓
2. HTTPartyOverrides intercepts request
   ↓
3. Helpers generates token: "client_name_timestamp"
   ↓
4. Helpers encrypts token with RSA public key
   ↓
5. Base64 encodes encrypted token
   ↓
6. Adds token to Secure-Token header
   ↓
7. HTTParty makes HTTP request
   ↓
8. Server (RobustServerSocket) validates token
   ↓
9. Response returned to application
```

## Integration with RobustServerSocket

RobustClientSocket is designed to work with [RobustServerSocket](../robust_server_socket) on the server side:

```
┌─────────────────────┐         Encrypted Token          ┌─────────────────────┐
│                     │   ──────────────────────────────> │                     │
│  RobustClientSocket │                                   │ RobustServerSocket  │
│   (Public Key)      │   <──────────────────────────────│   (Private Key)     │
│                     │         Authenticated Response    │                     │
└─────────────────────┘                                   └─────────────────────┘
```

### Server Setup

On the receiving service:

```ruby
# Server configuration
RobustServerSocket.configure do |config|
  config.private_key = ENV['PRIVATE_KEY']
  config.token_expiration_time = 300  # 5 minutes
  config.allowed_services = ['mobile-api', 'web-api']
  config.redis_url = ENV['REDIS_URL']
end

RobustServerSocket.load!

# In controller or middleware
def authenticate_request!
  token = request.headers['Secure-Token']
  client = RobustServerSocket::ClientToken.validate!(token)
  # Token is valid, proceed with request
rescue RobustServerSocket::ClientToken::InvalidToken
  render json: { error: 'Invalid token' }, status: :unauthorized
end
```

## Dependencies

- Ruby >= 2.7.7
- httparty (HTTP client)
- oj (Fast JSON)
- openssl (Encryption)


## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bundle exec rspec`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

## Authors

- **Taras Zhuk** - [@tee0zed](https://github.com/tee0zed)

## Support

For issues, questions, or contributions, please open an issue on the GitHub repository.

## Related Projects

- [RobustServerSocket](../robust_server_socket) - Server-side token validation
- [HTTParty](https://github.com/jnunemaker/httparty) - HTTP client library

## Security

For security issues, please email tee0zed@gmail.com directly instead of opening a public issue.
