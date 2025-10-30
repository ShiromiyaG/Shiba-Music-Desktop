function durationToText(ms) {
    var sec = Math.floor(ms / 1000)
    var minutes = Math.floor(sec / 60)
    var seconds = sec % 60
    return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
}