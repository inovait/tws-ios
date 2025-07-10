const originalPushState = history.pushState;

(function() {
history.pushState = function (state, title, url) {
    const baseUrl = window.location.origin;
    const path = typeof url !== 'undefined' ? url : '';
    const finalUrl = baseUrl + '' + path
    
    const currentUrl = location.href;

    window.webkit.messageHandlers.shouldIntercept.postMessage({
        url: finalUrl,
        payload: {
            state: state,
            title: title,
            path: url
        }
    })
}
})()

function pushStateContinuation(shouldIntercept, payload) {
    let args = [payload.state, payload.title, payload.path]
    if (shouldIntercept) {
        originalPushState.apply(history, args);
        window.history.back();
    } else {
        return originalPushState.apply(history, args);
    }
}
