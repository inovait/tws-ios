////
//  Copyright 2024 INOVA IT d.o.o.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


//
// Messaging swift about pushState changes
//

// Observe history.pushState and recieve new url
window.history.pushState = ( f => function pushState(){
    var ret = f.apply(this, arguments);
    const currentUrl = window.location.href
    window.webkit.messageHandlers.historyObserver.postMessage(currentUrl);
    return ret;
})(window.history.pushState);
