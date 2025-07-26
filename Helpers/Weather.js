function fetchCoordinates(city, callback, errorCallback) {
    var geoUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(city) + "&language=en&format=json";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var geoData = JSON.parse(xhr.responseText);
                    if (geoData.results && geoData.results.length > 0) {
                        callback(geoData.results[0].latitude, geoData.results[0].longitude);
                    } else {
                        errorCallback("City not found.");
                    }
                } catch (e) {
                    errorCallback("Failed to parse geocoding data.");
                }
            } else {
                errorCallback("Geocoding error: " + xhr.status);
            }
        }
    }
    xhr.open("GET", geoUrl);
    xhr.send();
}

function fetchWeather(latitude, longitude, callback, errorCallback) {
    var url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude + "&current_weather=true&current=relativehumidity_2m,surface_pressure&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var weatherData = JSON.parse(xhr.responseText);
                    callback(weatherData);
                } catch (e) {
                    errorCallback("Failed to parse weather data.");
                }
            } else {
                errorCallback("Weather fetch error: " + xhr.status);
            }
        }
    }
    xhr.open("GET", url);
    xhr.send();
}

function fetchCityWeather(city, callback, errorCallback) {
    fetchCoordinates(city, function(lat, lon) {
        fetchWeather(lat, lon, function(weatherData) {
            callback({
                city: city,
                latitude: lat,
                longitude: lon,
                weather: weatherData
            });
        }, errorCallback);
    }, errorCallback);
} 