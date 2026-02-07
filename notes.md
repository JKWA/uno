# Cheat

```javascript
let el = document.querySelector("[data-phx-main]")
let view = liveSocket.getViewByEl(el)

view.channel.push("event", {
    type: "click",
    event: "play_card",
    value: {player: "0", card_id: "14213"}
})
```
