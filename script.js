let interval;

function post(action, data) {
    return $.post(`https://${GetParentResourceName()}/${action}`, JSON.stringify(data));
}

function reset() {
    clearInterval(interval);
    $('#progress-bar-container').fadeOut(150);
    $('#progress').css('width', '0%');
    $('#multiplier').hide();
}

function end() {
    reset();
    post('end', { finished: true });
}

function progress(multiplier, duration) {
    $('#progress').css('width', '0%');
    const tick = 100;
    const progressPerTick = 100 / duration * tick * multiplier;
    let progress = 0;
    interval = setInterval(function() {
        if (progress < 100) {
            $('#progress').css('width', `${progress}%`);
            progress = Math.min(100, progress + progressPerTick);
        } else {
            clearInterval(interval);
            end();
        }
    }, tick);
}

function start(title, multiplier, duration) {
    $('#progress-bar-container').fadeIn(150);
    $('#title').text(title);
    if (multiplier !== 1) {
        const icon = multiplier < 1 ? 'down' : 'up';
        $('#multiplier').show();
        $('#multiplier > i')
            .removeClass('fa-angle-double-down fa-angle-double-up')
            .addClass(`fa-angle-double-${icon}`);
        $('#number').html(multiplier.toFixed(2));
    } else {
        $('#multiplier').hide();
    }
    progress(multiplier, duration);
}

window.onload = (e) => {
    window.addEventListener('message', (ev) => {
        if (ev.data.type == "StartTimer") {
            const { title, multiplier, duration } = ev.data;
            start(title, multiplier, duration)
        }

        if (ev.data.type == "Interrupt") {
            reset();
        }
    });
}
