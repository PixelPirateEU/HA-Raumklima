.pragma library

function normalizeUrl(rawUrl) {
    if (!rawUrl) {
        return "";
    }
    var trimmed = String(rawUrl).trim();
    while (trimmed.length > 0 && trimmed.charAt(trimmed.length - 1) === "/") {
        trimmed = trimmed.slice(0, -1);
    }
    return trimmed;
}

function testConnection(rawUrl, rawToken, callback) {
    var baseUrl = normalizeUrl(rawUrl);
    var token = rawToken ? String(rawToken).trim() : "";

    if (!baseUrl) {
        callback({
            ok: false,
            error: "Bitte eine gültige Home Assistant URL eingeben (z. B. http://homeassistant.local:8123)."
        });
        return;
    }
    if (!token) {
        callback({
            ok: false,
            error: "Bitte ein Long-Lived Access Token eingeben."
        });
        return;
    }

    var xhr = new XMLHttpRequest();
    xhr.timeout = 10000;
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) {
            return;
        }
        if (xhr.status === 200) {
            try {
                var resp = JSON.parse(xhr.responseText);
                callback({
                    ok: true,
                    message: resp.message || "API erreichbar",
                    version: resp.version || ""
                });
            } catch (e) {
                callback({
                    ok: false,
                    error: "Antwort von Home Assistant ist kein gültiges JSON."
                });
            }
        } else if (xhr.status === 401 || xhr.status === 403) {
            callback({
                ok: false,
                error: "Authentifizierung fehlgeschlagen (HTTP " + xhr.status + "). Bitte das Long-Lived Access Token prüfen."
            });
        } else if (xhr.status === 0) {
            callback({
                ok: false,
                error: "Keine Verbindung zu " + baseUrl + ". Bitte URL, Port und Netzwerk prüfen."
            });
        } else {
            callback({
                ok: false,
                error: "HTTP-Fehler " + xhr.status + ": " + (xhr.statusText || "Unbekannter Fehler")
            });
        }
    };

    try {
        xhr.open("GET", baseUrl + "/api/");
        xhr.setRequestHeader("Authorization", "Bearer " + token);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send();
    } catch (err) {
        callback({
            ok: false,
            error: "Verbindungsfehler: " + err.toString()
        });
    }
}

function fetchStates(rawUrl, rawToken, callback) {
    var baseUrl = normalizeUrl(rawUrl);
    var token = rawToken ? String(rawToken).trim() : "";

    if (!baseUrl || !token) {
        callback({
            ok: false,
            error: "Home Assistant URL oder Access Token fehlt."
        });
        return;
    }

    var xhr = new XMLHttpRequest();
    xhr.timeout = 12000;
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) {
            return;
        }
        if (xhr.status === 200) {
            try {
                var list = JSON.parse(xhr.responseText);
                if (!Array.isArray(list)) {
                    callback({
                        ok: false,
                        error: "Unerwartetes Datenformat von /api/states."
                    });
                    return;
                }
                var map = {};
                for (var i = 0; i < list.length; i++) {
                    var item = list[i];
                    if (item && item.entity_id) {
                        map[item.entity_id] = item;
                    }
                }
                callback({
                    ok: true,
                    statesList: list,
                    statesMap: map
                });
            } catch (e) {
                callback({
                    ok: false,
                    error: "Fehler beim Parsen der Sensordaten: " + e.toString()
                });
            }
        } else if (xhr.status === 401 || xhr.status === 403) {
            callback({
                ok: false,
                error: "Ungültiges Token (HTTP " + xhr.status + ")."
            });
        } else if (xhr.status === 0) {
            callback({
                ok: false,
                error: "Server nicht erreichbar (" + baseUrl + ")."
            });
        } else {
            callback({
                ok: false,
                error: "HTTP-Fehler " + xhr.status
            });
        }
    };

    try {
        xhr.open("GET", baseUrl + "/api/states");
        xhr.setRequestHeader("Authorization", "Bearer " + token);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send();
    } catch (err) {
        callback({
            ok: false,
            error: "Netzwerkfehler: " + err.toString()
        });
    }
}

function extractEntityValue(entityObj, kind) {
    if (!entityObj) {
        return {
            available: false,
            value: null,
            unit: kind === "humidity" ? "%" : "°C",
            friendlyName: "",
            targetTemp: null,
            lastUpdated: ""
        };
    }

    var stateStr = String(entityObj.state || "");
    var attrs = entityObj.attributes || {};
    var friendlyName = attrs.friendly_name || entityObj.entity_id || "";
    var entityId = String(entityObj.entity_id || "");
    var isUnavailable = (stateStr === "unavailable" || stateStr === "unknown" || stateStr === "");

    var rawVal = null;
    var unit = attrs.unit_of_measurement || (kind === "humidity" ? "%" : "°C");
    var targetTemp = null;

    if (entityId.indexOf("climate.") === 0 || entityId.indexOf("weather.") === 0) {
        if (kind === "humidity") {
            if (attrs.current_humidity !== undefined && attrs.current_humidity !== null) {
                rawVal = attrs.current_humidity;
            } else if (attrs.humidity !== undefined && attrs.humidity !== null) {
                rawVal = attrs.humidity;
            }
            unit = "%";
        } else {
            if (attrs.current_temperature !== undefined && attrs.current_temperature !== null) {
                rawVal = attrs.current_temperature;
            } else if (attrs.temperature !== undefined && attrs.temperature !== null) {
                rawVal = attrs.temperature;
            }
            if (attrs.temperature !== undefined && attrs.temperature !== null) {
                var parsedTarget = parseFloat(String(attrs.temperature).replace(",", "."));
                if (!isNaN(parsedTarget)) {
                    targetTemp = parsedTarget;
                }
            }
            unit = attrs.temperature_unit || "°C";
        }
    } else {
        if (!isUnavailable) {
            rawVal = stateStr;
        }
    }

    var num = rawVal !== null && rawVal !== undefined ? parseFloat(String(rawVal).replace(",", ".")) : NaN;
    if (isNaN(num)) {
        return {
            available: false,
            value: null,
            unit: unit,
            friendlyName: friendlyName,
            targetTemp: targetTemp,
            lastUpdated: entityObj.last_updated || ""
        };
    }

    return {
        available: true,
        value: num,
        unit: unit,
        friendlyName: friendlyName,
        targetTemp: targetTemp,
        lastUpdated: entityObj.last_updated || ""
    };
}

var LEGACY_ICON_MAP = {
    "user-home": "sofa.svg",
    "weather-clear-night": "bed.svg",
    "applications-games": "teddy-bear.svg",
    "computer": "laptop.svg",
    "weather-showers-scattered": "paper-roll.svg",
    "applications-utilities": "fridge.svg",
    "weather-Few-clouds": "balcony.svg",
    "folder-home": "texture-box.svg"
};

function normalizeRoomIcon(icon) {
    var raw = String(icon || "").trim();
    if (!raw) {
        return "sofa.svg";
    }
    if (LEGACY_ICON_MAP[raw]) {
        return LEGACY_ICON_MAP[raw];
    }
    return raw;
}

function guessRoomIcon(roomName) {
    var lower = String(roomName || "").toLowerCase();
    if (lower.indexOf("kind") >= 0 || lower.indexOf("kids") >= 0 || lower.indexOf("child") >= 0) {
        return "teddy-bear.svg";
    }
    if (lower.indexOf("schlaf") >= 0 || lower.indexOf("bed") >= 0) {
        return "bed.svg";
    }
    if (lower.indexOf("büro") >= 0 || lower.indexOf("buero") >= 0 || lower.indexOf("office") >= 0 || lower.indexOf("arbeit") >= 0) {
        return "laptop.svg";
    }
    if (lower.indexOf("bad") >= 0 || lower.indexOf("bath") >= 0 || lower.indexOf("dusch") >= 0 || lower.indexOf("wc") >= 0) {
        return "paper-roll.svg";
    }
    if (lower.indexOf("küch") >= 0 || lower.indexOf("kuech") >= 0 || lower.indexOf("kitchen") >= 0 || lower.indexOf("ess") >= 0) {
        return "fridge.svg";
    }
    if (lower.indexOf("garten") >= 0 || lower.indexOf("balkon") >= 0 || lower.indexOf("außen") >= 0 || lower.indexOf("aussen") >= 0 || lower.indexOf("terrasse") >= 0) {
        return "balcony.svg";
    }
    if (lower.indexOf("keller") >= 0 || lower.indexOf("garage") >= 0 || lower.indexOf("flur") >= 0 || lower.indexOf("diele") >= 0) {
        return "texture-box.svg";
    }
    return "sofa.svg";
}

function cleanRoomName(rawName) {
    if (!rawName) {
        return "";
    }
    var cleaned = String(rawName)
        .replace(/\b(temperatur|temperature|temp|luftfeuchtigkeit|luftfeuchte|feuchtigkeit|humidity|klima|climate|sensor|raumklima|thermostat)\b/gi, "")
        .replace(/[_:\-\/]+/g, " ")
        .replace(/\s+/g, " ")
        .trim();
    return cleaned;
}

function discoverSensorsAndRooms(statesList) {
    var tempSensors = [];
    var humiditySensors = [];
    var roomBuckets = {};

    if (!Array.isArray(statesList)) {
        return {
            tempSensors: tempSensors,
            humiditySensors: humiditySensors,
            discoveredRooms: []
        };
    }

    for (var i = 0; i < statesList.length; i++) {
        var item = statesList[i];
        if (!item || !item.entity_id) {
            continue;
        }
        var id = String(item.entity_id);
        var attrs = item.attributes || {};
        var devClass = String(attrs.device_class || "").toLowerCase();
        var unit = String(attrs.unit_of_measurement || "");
        var friendly = String(attrs.friendly_name || id);
        var lowerId = id.toLowerCase();
        var lowerFriendly = friendly.toLowerCase();

        var isClimate = id.indexOf("climate.") === 0;
        var isSensor = id.indexOf("sensor.") === 0;

        if (!isClimate && !isSensor) {
            continue;
        }

        var isTemp = isClimate
            || devClass === "temperature"
            || unit === "°C" || unit === "°F" || unit === "K"
            || (isSensor && (lowerId.indexOf("temp") >= 0 || lowerFriendly.indexOf("temperatur") >= 0));

        var isHum = (isClimate && (attrs.current_humidity !== undefined || attrs.humidity !== undefined))
            || devClass === "humidity"
            || (unit === "%" && (lowerId.indexOf("hum") >= 0 || lowerId.indexOf("feucht") >= 0 || lowerFriendly.indexOf("feucht") >= 0 || lowerFriendly.indexOf("humidity") >= 0));

        if (isTemp) {
            tempSensors.push({
                entityId: id,
                friendlyName: friendly,
                state: isClimate ? (attrs.current_temperature !== undefined ? attrs.current_temperature : item.state) : item.state,
                unit: unit || "°C"
            });
        }
        if (isHum) {
            humiditySensors.push({
                entityId: id,
                friendlyName: friendly,
                state: isClimate ? (attrs.current_humidity !== undefined ? attrs.current_humidity : item.state) : item.state,
                unit: "%"
            });
        }

        if (isTemp || isHum) {
            var roomLabel = cleanRoomName(friendly);
            if (!roomLabel) {
                var idPart = id.split(".")[1] || id;
                roomLabel = cleanRoomName(idPart);
            }
            if (roomLabel) {
                var key = roomLabel.toLowerCase();
                if (!roomBuckets[key]) {
                    roomBuckets[key] = {
                        name: roomLabel.charAt(0).toUpperCase() + roomLabel.slice(1),
                        icon: guessRoomIcon(roomLabel),
                        tempEntity: "",
                        humidityEntity: ""
                    };
                }
                if (isTemp && !roomBuckets[key].tempEntity) {
                    roomBuckets[key].tempEntity = id;
                }
                if (isHum && !roomBuckets[key].humidityEntity) {
                    roomBuckets[key].humidityEntity = id;
                }
            }
        }
    }

    tempSensors.sort(function(a, b) {
        return a.friendlyName.localeCompare(b.friendlyName);
    });
    humiditySensors.sort(function(a, b) {
        return a.friendlyName.localeCompare(b.friendlyName);
    });

    var discoveredRooms = [];
    for (var k in roomBuckets) {
        if (roomBuckets.hasOwnProperty(k)) {
            var r = roomBuckets[k];
            if (r.tempEntity || r.humidityEntity) {
                discoveredRooms.push(r);
            }
        }
    }
    discoveredRooms.sort(function(a, b) {
        return a.name.localeCompare(b.name);
    });

    return {
        tempSensors: tempSensors,
        humiditySensors: humiditySensors,
        discoveredRooms: discoveredRooms
    };
}
