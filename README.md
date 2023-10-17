# PayrentClientSocket

Gem to interact with Payrent API within infra  

## Usage

'config/initializers/payrent_client_socket.rb'

```ruby
PayrentClientSocket.configure do |c|
  c.keychain = {
    core: { # service name, used to identify the service must be same as service name in allowed_services in PayrentServerSocket 
      base_uri: 'https://core.payrent.com',
      public_key: '-----BEGIN PUBLIC KEY-----[...]' # public key of the service, from pair of keys by PayrentServerSocket
    },
    # [...]
  }

  PayrentClientSocket.load!
end
```

and then

```ruby
PayrentClientSocket::Core.post('/api/v1/rents', body: { rent: { amount: 1000, currency: 'EUR' }})
PayrentClientSocket::Core.get('/api/v1/rents', body: { rent: { amount: 1000, currency: 'EUR' }})
PayrentClientSocket::Core.patch('/api/v1/rents', body: { rent: { amount: 1000, currency: 'EUR' }})
```
