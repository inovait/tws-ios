//
// Docs: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation
//

//
// Section 1.: Helper variables
//

const locationWatchCallbacks = new Map();
const locationCallback = { success: null, error: null };

//
// Section 2.: Overrides
//

navigator.geolocation.getCurrentPosition = function(success, error, options) {
    const payload = createPayload("getCurrentPosition", 0, options);
    locationCallback.success = success;
    locationCallback.error = error;
    window.webkit.messageHandlers.locationHandler.postMessage(payload);
};

navigator.geolocation.watchPosition = function(success, error, options) {
    const id = Date.now();
    locationWatchCallbacks.set(id, { success, error })

    const payload = createPayload("watchPosition", id, options);
    window.webkit.messageHandlers.locationHandler.postMessage(payload);
    return id
};

navigator.geolocation.clearWatch = function(id) {
    locationWatchCallbacks.delete(id);
    const payload = createPayload("clearWatch", id, null);
    window.webkit.messageHandlers.locationHandler.postMessage(payload);
};

//
// Section 3.: Helpers
//

function createPayload(name, id, options) {
    return JSON.stringify({
        id: id,
        command: name,
        options: options
    })
}

//
// Section 4.: Call from Swift
//

// Section 4.1: Callbacks used when `watchPosition` request is processed

navigator.geolocation.iosWatchLocationDidUpdate = function(id, lat, lon, alt, ha, va, hd, spd) {
    const callbacks = locationWatchCallbacks.get(id);
    if (callbacks) {
        const { success, error } = callbacks;
        success({
            coords: {
                latitude: lat,
                longitude: lon,
                altitude: alt,
                accuracy: ha,
                altitudeAccuracy: va,
                heading: hd,
                speed: spd
            }
        });
    }

    return null;
}

navigator.geolocation.iosWatchLocationDidFailed = function(id, code) {
    const callbacks = locationWatchCallbacks.get(id);
    if (callbacks) {
        const { success, error } = callbacks;
        error({
            code: code,
            message: null
        });
    }
    navigator.geolocation.clearWatch(id);
    return null;
}

// Section 4.2: Callbacks used when `getCurrentPosition` request is processed

navigator.geolocation.iosLastLocation = function(lat, lon, alt, ha, va, hd, spd) {
    const success = locationCallback.success;
    if (success) {
        success({
            coords: {
                latitude: lat,
                longitude: lon,
                altitude: alt,
                accuracy: ha,
                altitudeAccuracy: va,
                heading: hd,
                speed: spd
            }
        });

        locationCallback.success = null;
        locationCallback.error = null;
    }

    return null;
}

navigator.geolocation.iosLastLocationFailed = function(code) {
    const error = locationCallback.error;
    if (error) {
        error({
            code: code,
            message: null
        });
    }

    locationCallback.success = null;
    locationCallback.error = null;

    return null;
}
