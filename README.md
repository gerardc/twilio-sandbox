twilio-sandbox
==============

Simple Sinatra application for prototyping Twilio workflows.

### Getting Started

1. Copy `twilio.yml.sample` to `twilio.yml` and add your account settings
2. Run `proxylocal 9393` to allow Twilio to reach your app
3. Run `URL=http://<your_unique_id>.proxylocal.com rake config_twilio` to configure Twilio to hit your `/voice` route
4. Run `rerun 'rackup -p 9393'` - to start a reloading local app
5. Open your app at `/agent_client`
5. Dial your number and try some of the commands below

### Commands

#### Examples

Here is an example set of commands your could run to manipulate the enqueued call:

- `curl http://<your_unique_id>.proxylocal.com/run/dial_client/agent_client`
- `curl http://<your_unique_id>.proxylocal.com/run/enqueue`
- `curl http://<your_unique_id>.proxylocal.com/run/dial_number/+123456789`
- `curl http://<your_unique_id>.proxylocal.com/run/enqueue`
- `curl http://<your_unique_id>.proxylocal.com/run/say_hello`

#### Call Hold

A sample call hold workflow is implemented which can be driven from the terminal.

To start, make a call using your number. The call with be enqueued with hold music. Next put the caller a specific conference:
```bash
curl http://<your_unique_id>.proxylocal.com/put_caller_in_conference -d ''
```

Next we need to call the agent in the browser. The call will ring in the browser, so allow it and the agent will be
put direcly into the conference with the caller:

```bash
curl http://<your_unique_id>.proxylocal.com/dial_agent -d ''
```

Now the two parties should be connected. Now we can put each on hold in turn:

Caller first:

```bash
curl http://<your_unique_id>.proxylocal.com/put_caller_on_hold -d ''
```

Then the agent:

```bash
curl http://<your_unique_id>.proxylocal.com/put_agent_on_hold -d ''
```

Then put them back into conference in reverse order. First the agent goes back into the conference:

```bash
curl http://<your_unique_id>.proxylocal.com/put_agent_in_conference -d ''
```

And then the caller:

```bash
curl http://<your_unique_id>.proxylocal.com/put_caller_in_conference -d ''
```

When you are finished you can hang up both parties:

```bash
curl http://<your_unique_id>.proxylocal.com/hangup_all -d ''
```

### Adding Commands

Simply follow the convention in `app.rb`!

