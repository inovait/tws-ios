(function () {
  const originalPushState = history.pushState;
  const pendingNavigations = {};
  let bypassNextPushState = false;

  function generateId() {
    return Date.now() + '_' + Math.random().toString(36).substring(2, 6);
  }

  function notifyNative(navId, method, url) {
    const message = {
      type: 'navigationAttempt',
      navId,
      method,
      url
    };

    window.webkit.messageHandlers.shouldIntercept.postMessage(message);
  }

  // Native calls this to allow the navigation
  window.__proceedWithNavigation = function (navId) {
    const nav = pendingNavigations[navId];
    if (!nav) return;

    bypassNextPushState = true; // Bypass one-time
    history.pushState(null, "", nav.url);
    window.dispatchEvent(new Event("popstate"));

    delete pendingNavigations[navId];
  };

  // Override pushState with bypass support
  history.pushState = function (state, title, url) {
    if (bypassNextPushState) {
      bypassNextPushState = false;
      return originalPushState.apply(this, arguments);
    }

    const navId = generateId();
    pendingNavigations[navId] = { method: 'pushState', url };
    notifyNative(navId, 'pushState', url);
    return; // Do not continue until native approves
  };

  // Intercept link clicks (optional)
  document.addEventListener(
    'click',
    function (e) {
      const anchor = e.target.closest('a');
      if (!anchor || !anchor.href || anchor.target === '_blank') return;

      const isSameOrigin = anchor.origin === window.location.origin;
      if (!isSameOrigin) return;

      const url = anchor.pathname + anchor.search + anchor.hash;
      const navId = generateId();
      e.preventDefault();

      pendingNavigations[navId] = { method: 'click', url };
      notifyNative(navId, 'click', url);
    },
    true
  );
})();

