# ExPeasant
Raspberry Pi + Nerves based AirAtomized.Farm controller prototype

Currently I use it in a air atomized aeroponic system prototype to control misting schedule. More to come (I hope so).
It works but is very far from any release-kind state.

The following description is very rough, sketchy and probably will be outdated soon enough.

## Modules

- Firmware: Nerves-specific part to allow the main component run on the Raspberry Pi device (RPi3 in my case)
- Peasant: the main part with the core component and the Phoenix LiveView-based UI

## Conceptions
It was intended to be a temporary solution until I made the bigger complex out of the cloud management system and a number of thin IoT controllers just to test an air-atomized aeroponics hardware with real plants. But it might be useful in its current (single fat IoT controller) form.

As I have never worked with such devices before I'm just trying to find better and convenient ways to make it functional therefore some design and implementation decisions can be controversial. If you have any suggestion on how to make things work better please share.

In general there are two main conceptions currently:

### Tool
A tool is a specific [probably hardware] device which a "peasant" use to have a specific "farm" work done. Each tool has a number of tool-specific actions and fire tools-specific events.

To describe a tool I've decided to use power of Elixir Protocols. Each tool is a struct (actually it is an Ecto model under the hood) made out of [Peasant.Tool.State](peasant/lib/peasant/tool/state.ex) base module, each action is a named after the specific action protocol, each tool must have supported actions protocols implementations. The only exception at the moment is the Attach action which has `for: Any` implementation.

An example of a tool is the [Peasant.Tools.SimpleRelay](peasant/lib/peasant/tools/simple_relay.ex) with [TurnOn](peasant/lib/peasant/tools/simple_relay/action/turn_on.ex) and [TurnOff](peasant/lib/peasant/tools/simple_relay/action/turn_off.ex) actions. It handles a simple relay module (via GPIO pull up\pull down).

All available tools and their actions are recognizing via specific namespaces analysis and protocol enumeration, so Protocol consolidation must be on. The required namespaces should be set in [config.exs](peasant/config/config.exs) (search for `config :peasant, Actions` option).

TODO: Implement a "chain of tools" when it is possible to introduce tools which are using other tools resources in a way the parent tools can control own resources availability: for example, a simple relay require a GPIO pin, and currently there is no way to control if a new Simple Relay wants to work with the same GPIO pin as one of the already added replays. If we add a GPIO tool first then we can link it with a simple relay instance after the first `attach` so it will deny the second `attach` with an another relay.

### Automation

Automation is a list of tools actions, like a cyclic schedule. 

For example, one of my current automations:

![Automation Screenshot 1](images/automation-001.png?raw=true)

![Automation Screenshot 2](images/automation-002.png?raw=true)


More main part implementation details is in the `peasant` (README)[peasant/README.md], but it can (and most possibly is) outdated.

## Supported tools (devices)

- [X] Simple GPIO-pin controlled relay 
- [ ] ds18b20 1wire temperature sensor

## UI
UI is based on the Phoenix LiveView. 

Currently it allows to 

list Tools:

![Tools list](images/tools-001.png?raw=true)

list current, add new automations:

![Automations list](images/automation-003.png?raw=true)

start, stop a specific automation, add, delete, pause or alter automation steps.

UI doesn't have any tests as of yet.

## OTA Updates

The project uses [Nerves Hub](https://www.nerves-hub.org/) for automatic OTA firmware updates.

## Other
Please don't forget to change required `firmware` configs. You should at lease create `firmware/config/target.secret.exs` file with salts:

```elixir
import Config

config :peasant, PeasantWeb.Endpoint,
  secret_key_base: "YOUR SECRET KEY BASE: use `mix phx.gen.secret`",
  live_view: [signing_salt: "YOUR SIGNING KEY: use `mix phx.gen.secret 32`"]
```

Also the project uses VintageNet WiFi Wizard to configure wifi: it creates a WiFi network with SSID `peasant_wifi` if no networks were configured before, you can connect into it and enter your main SSID\password settings.

You can use try to use `http://peasant.local` URL to connect to the UI or connect with ssh to the Nerves command prompt.

The following text is almost unaltered original Nerves poncho example README. 

## Hardware

This example serves a Phoenix-based web page over the network. The steps below
assume you are using a Raspberry Pi Zero, which allows you to connect a single
USB cable to the port marked "USB" to get both network and serial console
access to the device. By default, this example will use the virtual Ethernet
interface provided by the USB cable, assign an IP address automatically, and
make it discoverable using mDNS (Bonjour). For more information about how to
configure the network settings for your environment, including WiFi settings,
see the [`vintage_net` documentation](https://hexdocs.pm/vintage_net/).

## How to Use this Repository

1. Connect your target hardware to your host computer or network as described
   above
2. Prepare your Phoenix project to build JavaScript and CSS assets:

    ```bash
    # These steps only need to be done once.
    cd peasant
    mix deps.get
    cd assets
    npm install
    ```

3. Build your assets and prepare them for deployment to the firmware:

    ```bash
    # Still in ui/assets directory from the prior step.
    # These steps need to be repeated when you change JS or CSS files.
    node node_modules/webpack/bin/webpack.js --mode production
    cd ../
    mix phx.digest
    ```

4. Change to the `firmware` app directory

    ```bash
    cd ../firmware
    ```

5. Specify your target and other environment variables as needed:

    ```bash
    export MIX_TARGET=rpi3
    # If you're using WiFi (not necessary as WiFi should be configured via wizard):
    # export NERVES_NETWORK_SSID=your_wifi_name
    # export NERVES_NETWORK_PSK=your_wifi_password
    ```

6. Get dependencies, build firmware, and burn it to an SD card:

    ```bash
    mix deps.get
    mix firmware
    mix firmware.burn
    ```

7. Insert the SD card into your target board and connect the USB cable or otherwise power it on
8. Wait for it to finish booting (5-10 seconds)
9. Open a browser window on your host computer to `http://peasant.local/`
10. You should see a "Tech'n'Plants Peasant" main page

[Phoenix Framework]: http://www.phoenixframework.org/
[Poncho Projects]: http://embedded-elixir.com/post/2017-05-19-poncho-projects/

## Learn More

* Official docs: https://hexdocs.pm/nerves/getting-started.html
* Official website: https://nerves-project.org/
* Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
* Source: https://github.com/nerves-project/nerves
