# esx_report
This resource for ESX adds the ability to send reports to the admins in game and on discord.

## Requirements

* [es_extended](https://github.com/ESX-Org/es_extended) 

## Download & Installation

### Using Git

```
cd resources
git clone https://github.com/WillemSpoelstra/esx_report [esx]/esx_report
```

### Manually

* Download [esx_report](https://github.com/WillemSpoelstra/esx_report/archive/master.zip)
* Put it in the `[esx]` directory

## Installation
* Add this to your `server.cfg`:

```
start esx_report
```

## Configuration

### dicord webhook
In order to use the discord messages you need to make a webhook for a text channel. You can do this by:

1. Clicking on the grear icon.
2. Going to `Webhooks`
3. Clicking on `Create webhook`
4. Give it a name like `Report bot`
5. Copy the url
6. paste the url in the config like this:	`Config.webhookurl   = '[your_url]'`
7. enable the hook in the config like this: `Config.useDiscord = true`