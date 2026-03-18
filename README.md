# ha-mtmr

Home Assistant controls for the macOS Touch Bar via [MTMR](https://github.com/Toxblh/MTMR).

- Toggle lights and switches with live state display
- Brightness up/down for any dimmable light
- Trigger scenes, scripts, and automations
- Display live sensor readings (temperature, CO2, etc.)
- Presence indicator - shows your current room when home (bed, desk, etc.) or your HA zone when away
- Open HA in the browser

![The image displays the top section of a user interface with various icons and text on a black background. From left to right, there is a light bulb icon, text reading "O Desk O NL," followed by sun icons and a lightning bolt icon, and "O Bed." Next are media control icons for play/pause, previous, and next tracks. The text "RAYE – Nightingale Lane" is followed by a sun icon with "17°C." Further right is a muted speaker icon, a graph, a crescent moon icon, a circle icon, more sun icons, and a battery icon showing 98% with the time left "2:01."](touchbar.png)

## Setup

1. Install by cloning the repo then copying `.ha` to your home directory

```bash
cp ha ~/.ha
chmod +x ~/.ha
cp ha_config.example ~/.ha_config
```

1. Configure

Edit `~/.ha_config`:

```bash
HA_URL="https://your-ha-domain.com"
HA_TOKEN="your_long_lived_access_token"
```

Get a token in HA → Profile → Long-Lived Access Tokens.

1. Add to MTMR

Copy items from `mtmr-items.jsonc` into your `~/Library/Application Support/MTMR/items.json`, replacing entity IDs with your own. Find your entity IDs in HA → Developer Tools → States.

Reload MTMR.

## Commands

```bash
~/.ha status <entity_id> [ShortName]   # show state for Touch Bar display
~/.ha toggle <entity_id>               # toggle on/off
~/.ha brightness_up <entity_id>        # +10% brightness (turns on at 50% if off)
~/.ha brightness_down <entity_id>      # -10% brightness (turns off at 0%)
~/.ha scene_activate <entity_id>       # activate a scene
~/.ha script <entity_id>               # run a script
~/.ha automation <entity_id>           # trigger an automation
~/.ha sensor <entity_id> [ShortName]   # display a sensor value with unit
~/.ha person <entity_id>               # show home/away for a person entity
~/.ha where                            # show current room or zone (edit entity IDs in script)
~/.ha open                             # open Home Assistant in the browser
```

## Presence / where

The `where` command checks `person.person_name` and cross-references Aqara FP2 bedroom zones. Edit the entity IDs in the `where` case of `ha` to match your setup.

| State | Display |
|-------|---------|
| At desk (FP2 zone) | 💻 Desk |
| In bed (FP2 zone) | 🛏 Bed |
| Elsewhere in bedroom | 🛏 Bedroom |
| Home, location unknown | 🏠 Home |
| At gym zone | 🏋 Gym |
| At work zone | 💼 Work |
| Away | 🚗 Away |

## Notes

- Tested on macOS 15 with MTMR 0.27
- Requires `curl` and `python3` (both included with macOS)
- `shellScript` action type crashes MTMR - actions must use `appleScript` with `do shell script`
