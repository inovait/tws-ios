//
// Section 1.: Helper variables
//

const locationWatchCallbacks = new Map();
const locationCallbacks = new Map();

//
// Section 2.: Helpers
//

function createPayload(name, id, options) {
    return JSON.stringify({
        id: id,
        command: name,
        options: options
    });
}

//
// Section 3.: Overrides
//

// https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/getCurrentPosition
navigator.geolocation.getCurrentPosition = function(success, error, options) {
    // Integer ID does not work when multiple webviews are sharing one location provider
    const id = Date.now();  // Generate a unique ID using the counter
    locationCallbacks.set(id, { success, error }); // Store the callbacks using the id
    const payload = createPayload("getCurrentPosition", id, options); // Payload dispatched to iOS
    window.webkit.messageHandlers.locationHandler.postMessage(payload); // Send command
};

// https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/watchPosition
navigator.geolocation.watchPosition = function(success, error, options) {
    // Integer ID does not work when multiple webviews are sharing one location provider
    const id = Date.now();  // Generate a unique ID using the counter
    locationWatchCallbacks.set(id, { success, error }); // Store the callbacks using the id
    const payload = createPayload("watchPosition", id, options); // Payload dispatched to iOS
    window.webkit.messageHandlers.locationHandler.postMessage(payload); // Send command
    return id;
};

// https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/clearWatch
navigator.geolocation.clearWatch = function(id) {
    locationWatchCallbacks.delete(id); // Remove the callbacks using the id
    const payload = createPayload("clearWatch", id, null); // Payload dispatched to iOS
    window.webkit.messageHandlers.locationHandler.postMessage(payload); // Send command
};

//
// Section 4.: Call from Swift
//

// Section 4.1: Callbacks used when `watchPosition` request is processed in iOS world

navigator.geolocation.iosWatchLocationDidUpdate = function(id, lat, lon, alt, ha, va, hd, spd) {
    const callbacks = locationWatchCallbacks.get(id);
    if (callbacks) {
        const { success } = callbacks;
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
        const { error } = callbacks;
        error({
            code: code,
            message: null
        });
    }

    locationWatchCallbacks.delete(id); // Remove the callback after it's used
    return null;
}

// Section 4.2: Callbacks used when `getCurrentPosition` request is processed in iOS world

navigator.geolocation.iosLastLocation = function(id, lat, lon, alt, ha, va, hd, spd) {
    const callbacks = locationCallbacks.get(id);
    if (callbacks) {
        const { success } = callbacks;
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

        locationCallbacks.delete(id); // Remove the callback after it's used
    }

    return null;
}

navigator.geolocation.iosLastLocationFailed = function(id, code) {
    const callbacks = locationCallbacks.get(id);
    if (callbacks) {
        const { error } = callbacks;
        error({
            code: code,
            message: null
        });
    }

    locationCallbacks.delete(id); // Remove the callback after it's used

    return null;
}
