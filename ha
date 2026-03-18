#!/bin/bash
# Home Assistant helper for MTMR Touch Bar buttons
# Usage: ~/.ha <action> [entity_id] [display_name]
#   Actions: status, toggle, brightness_up, brightness_down,
#            person, where, script, automation, scene, sensor, open

source ${HOME}/.ha_config

ACTION="$1"
ENTITY="$2"
DOMAIN="${ENTITY%%.*}"
SHORT_KEY="${ENTITY##*.}"
# Turn underscores into spaces, capitalize first word (overridable via $3)
AUTO_SHORT="$(echo "${SHORT_KEY//_/ }" | awk '{print toupper(substr($1,1,1)) substr($1,2)}')"
SHORT="${3:-$AUTO_SHORT}"

get_state() {
  curl -sf \
    -H "Authorization: Bearer $HA_TOKEN" \
    -H "Content-Type: application/json" \
    "$HA_URL/api/states/$ENTITY" 2>/dev/null
}

case "$ACTION" in

  status)
    if [ "$DOMAIN" = "light" ]; then
      RESPONSE=$(get_state)
      STATE=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['state'])" 2>/dev/null)
      if [ "$STATE" = "on" ]; then
        PCT=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); b=d['attributes'].get('brightness',255); print(int(round(b/255*100)))" 2>/dev/null)
        echo "💡 ${PCT}%"
      else
        echo "○ $SHORT"
      fi
    elif [ "$DOMAIN" = "switch" ] || [ "$DOMAIN" = "input_boolean" ]; then
      RESPONSE=$(get_state)
      STATE=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['state'])" 2>/dev/null)
      [ "$STATE" = "on" ] && echo "⚡ $SHORT" || echo "○ $SHORT"
    else
      RESPONSE=$(get_state)
      echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['state'])" 2>/dev/null
    fi
    ;;

  toggle)
    curl -sf -X POST \
      -H "Authorization: Bearer $HA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"entity_id\": \"$ENTITY\"}" \
      "$HA_URL/api/services/homeassistant/toggle" > /dev/null 2>&1
    ;;

  brightness_up)
    curl -sf \
      -H "Authorization: Bearer $HA_TOKEN" \
      -H "Content-Type: application/json" \
      "$HA_URL/api/states" 2>/dev/null | python3 -c "
import sys, json, urllib.request
ha_url = '$HA_URL'
ha_token = '$HA_TOKEN'
headers = {'Authorization': 'Bearer ' + ha_token, 'Content-Type': 'application/json'}
on_lights = [s for s in json.load(sys.stdin) if s['entity_id'].startswith('light.') and s['state'] == 'on']
for light in on_lights:
    cur = int(light['attributes'].get('brightness', 128))
    new = min(255, cur + 26)
    req = urllib.request.Request(ha_url + '/api/services/light/turn_on',
        data=json.dumps({'entity_id': light['entity_id'], 'brightness': new}).encode(),
        headers=headers, method='POST')
    urllib.request.urlopen(req)
" 2>/dev/null
    ;;

  brightness_down)
    curl -sf \
      -H "Authorization: Bearer $HA_TOKEN" \
      -H "Content-Type: application/json" \
      "$HA_URL/api/states" 2>/dev/null | python3 -c "
import sys, json, urllib.request
ha_url = '$HA_URL'
ha_token = '$HA_TOKEN'
headers = {'Authorization': 'Bearer ' + ha_token, 'Content-Type': 'application/json'}
on_lights = [s for s in json.load(sys.stdin) if s['entity_id'].startswith('light.') and s['state'] == 'on']
for light in on_lights:
    cur = int(light['attributes'].get('brightness', 128))
    new = max(0, cur - 26)
    if new <= 0:
        req = urllib.request.Request(ha_url + '/api/services/light/turn_off',
            data=json.dumps({'entity_id': light['entity_id']}).encode(),
            headers=headers, method='POST')
    else:
        req = urllib.request.Request(ha_url + '/api/services/light/turn_on',
            data=json.dumps({'entity_id': light['entity_id'], 'brightness': new}).encode(),
            headers=headers, method='POST')
    urllib.request.urlopen(req)
" 2>/dev/null
    ;;

  person)
    RESPONSE=$(get_state)
    STATE=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['state'])" 2>/dev/null)
    NAME=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); fn=d['attributes'].get('friendly_name','?'); print(fn.split()[0])" 2>/dev/null)
    [ "$STATE" = "home" ] && echo "🏠 $NAME" || echo "🚗 $NAME"
    ;;

  script)
    # Run a HA script - entity_id should be script.your_script
    curl -sf -X POST \
      -H "Authorization: Bearer $HA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"entity_id\": \"$ENTITY\"}" \
      "$HA_URL/api/services/script/turn_on" > /dev/null 2>&1
    ;;

  automation)
    # Trigger a HA automation - entity_id should be automation.your_automation
    curl -sf -X POST \
      -H "Authorization: Bearer $HA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"entity_id\": \"$ENTITY\"}" \
      "$HA_URL/api/services/automation/trigger" > /dev/null 2>&1
    ;;

  scene)
    # Activate a scene - entity_id should be scene.your_scene
    # Displays the scene name for use as a button label
    if [ -z "$ENTITY" ]; then
      echo "Scene"
    else
      RESPONSE=$(get_state)
      NAME=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['attributes'].get('friendly_name', '$SHORT'))" 2>/dev/null)
      echo "🎨 ${3:-$NAME}"
    fi
    ;;

  scene_activate)
    curl -sf -X POST \
      -H "Authorization: Bearer $HA_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"entity_id\": \"$ENTITY\"}" \
      "$HA_URL/api/services/scene/turn_on" > /dev/null 2>&1
    ;;

  sensor)
    # Display a sensor value - e.g. temperature, humidity
    RESPONSE=$(get_state)
    STATE=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['state'])" 2>/dev/null)
    UNIT=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['attributes'].get('unit_of_measurement',''))" 2>/dev/null)
    echo "$SHORT $STATE$UNIT"
    ;;

  open)
    # Open Home Assistant in the browser
    open "$HA_URL"
    ;;

  where)
    # Get person state - edit entity IDs below to match your setup
    PERSON=$(curl -sf -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/states/person.your_name" 2>/dev/null)
    STATE=$(echo "$PERSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['state'])" 2>/dev/null)

    case "$STATE" in
      home)
        # Check FP2 bedroom zones
        DESK=$(curl -sf -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/states/binary_sensor.your_fp2_desk_zone" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['state'])" 2>/dev/null)
        BED=$(curl -sf -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/states/binary_sensor.your_fp2_bed_zone" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['state'])" 2>/dev/null)
        BEDROOM=$(curl -sf -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/states/binary_sensor.your_fp2_bedroom_zone" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['state'])" 2>/dev/null)
        if [ "$DESK" = "on" ]; then
          echo "💻 Desk"
        elif [ "$BED" = "on" ]; then
          echo "🛏 Bed"
        elif [ "$BEDROOM" = "on" ]; then
          echo "🛏 Bedroom"
        else
          echo "🏠 Home"
        fi
        ;;
      gym)       echo "🏋 Gym" ;;
      work)      echo "💼 Work" ;;
      not_home)  echo "🚗 Away" ;;
      *)         echo "🚗 $STATE" ;;
    esac
    ;;

esac
