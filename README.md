# RobustClientSocket

Gem to interact with Robust API within infra  

## Usage

'config/initializers/robust_client_socket.rb'

```ruby
RobustClientSocket.configure do |c|
  c.header_name = 'Secure-Token' # header name, used to store token (default: 'Secure-Token')
  c.client_name = 'core' # client name, used to identify the service must be same as service name in allowed_services in RobustServerSocket 
  c.core = { # server name, name that will be resolved to RobustClientSocket::[NAME]
    base_uri: 'https://core.payrent.com',
    public_key: '-----BEGIN PUBLIC KEY-----[...]' # public key of the service, from pair of keys by RobustServerSocket
  }
  # [...]
end

RobustClientSocket.load!
```

and then

```ruby
RobustClientSocket::Core.post('/api/v1/rents', body: { rent: { amount: 1000, currency: 'EUR' }})
RobustClientSocket::Core.get('/api/v1/rents', body: { rent: { amount: 1000, currency: 'EUR' }})
RobustClientSocket::Core.patch('/api/v1/rents', body: { rent: { amount: 1000, currency: 'EUR' }})
```
