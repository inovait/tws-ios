let pendingNavigation = {}

function generateId() {
  return 'id-' + Date.now();
}

function notifyNative(navId, url) {
    const message = {
        navId: navId,
        url: url
    };
    
    window.webkit.messageHandlers.shouldIntercept.postMessage(message);
}

function simulateClick(navId, shouldSimulate) {
    if (!shouldSimulate) {
        delete pendingNavigation.navId
        return
    }
   
    const event = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window
    })
    event._isSimulated = true
    pendingNavigation[navId].element.dispatchEvent(event)
}

(function () {
    document.addEventListener('click', function(e) {
        const anchor = e.target.closest('a');
        if (!anchor || !anchor.href || anchor.target === '_blank') return;

        const isSameOrigin = anchor.origin === window.location.origin;
        if (!isSameOrigin) return;
        if (e._isSimulated) return;
        
        e.stopImmediatePropagation()
        e.preventDefault()
        const url = anchor.href;
        const navId = generateId()
        pendingNavigation[navId] = {
            element: anchor
        }
        
        notifyNative(navId, url)
    }, true)
})()
