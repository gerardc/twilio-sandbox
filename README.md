twilio-sandbox
==============

Simple Sinatra application for prototyping Twilio workflows.

### Getting Started

1. Copy `twilio.yml.sample` to `twilio.yml` and add your account settings
2. Run `proxylocal 9393` to allow Twilio to reach your app
3. Run `URL=http://<your_unique_id>.proxylocal.com rake config` to configure Twilio to hit your `/voice` route
4. Run `shotgun` or `rerun 'rackup -p 9393'` - to start a reloading local app
5. Open your app at `/your_client_name`
5. Dial your number and try some of the commands below

### Commands

Here is an example set of commands your could run to manipulate the enqueued call:

- `curl http://<your_unique_id>.proxylocal.com/run/dial_client/your_client_name`
- `curl http://<your_unique_id>.proxylocal.com/run/enqueue`
- `curl http://<your_unique_id>.proxylocal.com/run/dial_number/+123456789`
- `curl http://<your_unique_id>.proxylocal.com/run/enqueue`
- `curl http://<your_unique_id>.proxylocal.com/run/say_hello`

### Adding Commands

Simply follow the convention in `app.rb`!

### TODO

- Add conference workflow

