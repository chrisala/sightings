/*
 * Copyright (C) 2012 Atlas of Living Australia
 * All Rights Reserved.
 *
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 */

/**
 *
 * Javascript to manage location and date definitions and their representation on the page.
 *
 * User: markew
 * Date: 16/07/12
 */
/* Manages locations --------------------------------------------------------------- */
$(function() {
    $('#time').mask("99:99");
    $("#date").datepicker({
        dateFormat: "dd-mm-yy",
        maxDate: "+0",
        appendText: " (dd-mm-yyyy)",
        numberOfMonths: 1
    });
    screenLocation.init();
    screenDate.init();
    // preload date and time if they are supplied
    if (typeof eventDate !== 'undefined') {
        if (eventDate !== "" && eventDate !== 'null') {
            new DateTime().setFromStoredFormat(eventDate, eventTime).putToScreen();
        }
    }
});

var screenLocation = {
    latitudeField: null,
    longitudeField: null,
    autoLookup: true,
    usingReverseGeocodedLocality: false,
    geocoder: null,
    listeners: [],
    init: function () {
        var that = this, lat, lng;
        this.latitudeField = $('#latitude');
        this.longitudeField = $('#longitude');
        this.geocoder = new google.maps.Geocoder();

        // catch changes in lat and lon
        $('#latitude,#longitude').change(function () {
            lat = that.getLat();
            lng = that.getLng();

            // don't use a configured listener for this so we avoid infinite loops
            mainMap.setMarker(lat, lng);

            // notify other listeners
            $.each(that.listeners, function (i, lis) {
                lis.handler.apply(that, ['latLngChange', new google.maps.LatLng(lat, lng)]);
            });
        });

        // catch edits to the locality field
        $('#location').change( function () {
            that.setUsingReverseGeocodedLocality(false);
        });
        $("#location").keypress(function(e) {
            if(e.which == 13) {
                that.geocodeLookup();
                return false;
            }
        });
        // wire location lookups
        $('#reverseLookup').click(function () {
            var locText = that.getLocality();
            if (locText === "") { return; }
            that.geocoder.geocode({
                address: locText,
                bounds: mainMap.map.getBounds()},
                function (results, status) {
                    var latLng;
                    if (status == google.maps.GeocoderStatus.OK) {
                        latLng = results[0].geometry.location;
                        $('#latitude').val(latLng.lat());
                        $('#longitude').val(latLng.lng()).change();
                        mainMap.show();
                    }
                });
        });
        $('#lookup').click(function () {
            var lat = $('#latitude').val(),
                lng = $('#longitude').val();
            if (lat === "" || lng === "") { return; }
            that.geocoder.geocode({
                location: new google.maps.LatLng(lat, lng)},
                function (results, status) {
                    if (status == google.maps.GeocoderStatus.OK) {
                        that.setLocality(results[1].formatted_address);
                        that.setUsingReverseGeocodedLocality(true);
                    }
                });
        });

        // wire geocode icon
        $('#isLookedUp').click(function () {
            if (that.getLocality() === "") { return; }
            that.setUsingReverseGeocodedLocality(!that.usingReverseGeocodedLocality);
        });

        // listen for dragend events in main map so we can modify locality
        mainMap.addListener({handler: function (mouseEvent, event) {
            if (event === 'dragend') {
                if (that.getLocality() === "" || that.usingReverseGeocodedLocality) {
                    // reverse geocode locality
                    that.reverseGeocodeLocality(that.getLat(), that.getLng());
                }
            }
        }});
    },
    geocodeLookup: function(){
        var locText = this.getLocality();
        if (locText === "") { return; }
        this.geocoder.geocode({
            address: locText,
            bounds: mainMap.map.getBounds()
        },
        function (results, status) {
            var latLng;
            if (status == google.maps.GeocoderStatus.OK) {
                latLng = results[0].geometry.location;
                $('#latitude').val(latLng.lat());
                $('#longitude').val(latLng.lng()).change();
                mainMap.show();
            }
        });
    },
    getAll: function () {
        var l = {
            decimalLatitude: this.getLat(),
            decimalLongitude: this.getLng(),
            verbatimLatitude: $('#verbatimLatitude').val(),
            verbatimLongitude: $('#verbatimLongitude').val(),
            locality: this.getLocality(),
            georeferenceProtocol: this.getSource()
            },
            other = $('#otherSource').val();
        if (this.usingReverseGeocodedLocality) {
            l.usingReverseGeocodedLocality = true;
        }
        if (l.georeferenceProtocol === 'GPS device') {
            l.geodeticDatum = $('#geodeticDatum').val();
        }
        if (l.georeferenceProtocol === 'other') {
            l.otherSource = other;
        }
        if (l.georeferenceProtocol === 'physical map') {
            l.physicalMapScale = $('#physicalMapScale').val();
        }
        return l;
    },
    setLatLng: function (lat, lng, options) {
        var opts = options || {};
        this.setLat(lat, opts.noNotify);
        this.setLng(lng, opts.noNotify);
        if (opts.autoLookup && (this.getLocality() === "" || this.usingReverseGeocodedLocality)) {
            // reverse geocode locality
            this.reverseGeocodeLocality(lat, lng);
        }
    },
    getLat: function () {
        return $('#latitude').val();
    },
    getLng: function () {
        return $('#longitude').val();
    },
    setLat: function (num, noNotify) {
        this.latitudeField.val(num);//limit(num));
        if (noNotify !== true) {
            this.latitudeField.change();
        }
    },
    setLng: function (num, noNotify) {
        this.longitudeField.val(num);//limit(num));
        if (noNotify !== true) {
            this.longitudeField.change();
        }
    },
    getSource: function () {
        return $('#georeferenceProtocol').val();
    },
    clearVerbatimLatLon: function () {
        $('#verbatimLatitude').val('');
        $('#verbatimLongitude').val('');
    },
    setSource: function (source) {
        $('#georeferenceProtocol').val(source).change();
    },
    getLocality: function () {
        return $('#location').val();
    },
    setLocality: function (source) {
        $('#location').val(source).change();
    },
    setUsingReverseGeocodedLocality: function (value) {
        if (value === true) {
            $('#isLookedUp').removeClass('lookup-off');
            $('#isLookedUp').attr('title','Description has been looked up from the coordinates');
            this.usingReverseGeocodedLocality = true;
        } else {
            $('#isLookedUp').addClass('lookup-off');
            $('#isLookedUp').attr('title','');
            this.usingReverseGeocodedLocality = false;
        }
    },
    isValid: function () {
        return new Location().loadFromScreen().isValid();
    },
    reverseGeocodeLocality: function (lat, lng) {
        var latLng = new google.maps.LatLng(lat, lng),
            that = this;
        this.geocoder.geocode({'latLng': latLng}, function (results, status) {
            if (status === google.maps.GeocoderStatus.OK) {
                if (results[0]) {
                    that.setLocality(results[0].formatted_address);
                    that.setUsingReverseGeocodedLocality(true);
                }
            }
        });
    },
    addListener: function(listener) {
        this.listeners.push(listener);
    },
    removeListener: function(listener) {
        this.listeners.remove(listener);
    }
};

function Location () {
    this.decimalLatitude = null;
    this.decimalLongitude = null;
    this.verbatimLatitude = "";
    this.verbatimLongitude = "";
    this.locality = "";
    this.usingReverseGeocodedLocality = "false";
    this.georeferenceProtocol = "";
    this.geodeticDatum = "";
    this.physicalMapScale = "";
    this.otherSource = "";
}

Location.prototype.isValid = function () {
    return hasValue(this.decimalLatitude) && hasValue(this.decimalLongitude);
};

Location.prototype.isDecimalDegrees = function (x) {
    return !(x === undefined || isNaN(x));
};

Location.prototype.isDegMinSec = function (o) {
    return $.isArray(o.lat) && $.isArray(o.lng);
};

Location.prototype.degMinSecToString = function (num, ref) {
    var sign = (ref === 'S' || ref === 'W') ? "-" : "";
    return sign + num[0] + " " + num[1] + " " + num[2];
};

Location.prototype.toDecimalDegrees = function (num, ref) {
    // expect num to be an array of length 3
    if (num.length !== 3) { return 0 }
    //console.log(num[0] + " " + num[1] + " " + num[2]);
    var degrees = num[0],
        minutes = num[1],
        seconds = num[2],
        // determine the num decimal places of minutes and seconds (so we don't artificially add 'accuracy')
        minutesPlaces = numDecimalPlaces(minutes,'.'),
        secondsPlaces = numDecimalPlaces(seconds,'.'),
        apparentAccuracy;

    /* roughly calculate the apparent accuracy based on:
        1 second ~= .0003 degree so take 4 places as a min
        add a decimal place for each decimal place in the seconds value
        1 minute ~= .0166 degree so add start with 2 and add 1 place for each decimal place in minutes
        take the greater of the two estimates
     */
    apparentAccuracy = Math.max(4 + secondsPlaces, 2 + minutesPlaces);
    //console.log(apparentAccuracy);
    degrees = degrees + minutes/60 + seconds/3600;
    // limit result to the same apparent resolution as the input
    degrees = degrees.toFixed(apparentAccuracy);
    if (ref === 'S' || ref === 'W') {
        degrees = -degrees;
    } else {
        degrees = +degrees;
    }
    return degrees;
};

Location.prototype.set = function (data) {
    var that = this;
    $.each(['locality','georeferenceProtocol','geodeticDatum','physicalMapScale','otherSource'], function (i,prop) {
        if (data[prop] !== undefined) {
            that[prop] = data[prop];
        }
    });
    if (data.latLng !== undefined) {
        if (this.isDegMinSec(data.latLng)) {
            this.verbatimLatitude = this.degMinSecToString(data.latLng.lat, data.latLng.latRef);
            this.verbatimLongitude = this.degMinSecToString(data.latLng.lng, data.latLng.lngRef);
            this.decimalLatitude = this.toDecimalDegrees(data.latLng.lat, data.latLng.latRef);
            this.decimalLongitude = this.toDecimalDegrees(data.latLng.lng, data.latLng.lngRef);
        } else {
            this.verbatimLatitude = data.latLng.lat;
            this.verbatimLongitude = data.latLng.lng;
            this.decimalLatitude = this.verbatimLatitude;
            this.decimalLongitude = this.verbatimLongitude;
        }
        // reverse geocode locality if blank

    }
    return this;
};

Location.prototype.loadFromScreen = function () {
    this.decimalLatitude = screenLocation.getLat();
    this.decimalLongitude = screenLocation.getLng();
    this.verbatimLatitude = $('#verbatimLatitude').val();
    this.verbatimLongitude = $('#verbatimLongitude').val();
    this.locality = screenLocation.getLocality();
    this.usingReverseGeocodedLocality = screenLocation.usingReverseGeocodedLocality;
    this.georeferenceProtocol = screenLocation.getSource();
    this.geodeticDatum = $('#geodeticDatum').val();
    if (this.georeferenceProtocol === 'physical map') {
        this.physicalMapScale = $('#physicalMapScale').val();
    }
    this.otherSource = $('#otherSource').val();
    return this;
};

Location.prototype.loadFromBookmark = function (bkm) {
    this.decimalLatitude = bkm.decimalLatitude;
    this.decimalLongitude = bkm.decimalLongitude;
    this.verbatimLatitude = bkm.verbatimLatitude;
    this.verbatimLongitude = bkm.verbatimLongitude;
    this.locality = bkm.locality;
    this.usingReverseGeocodedLocality = bkm.usingReverseGeocodedLocality;
    this.georeferenceProtocol = bkm.georeferenceProtocol;
    this.geodeticDatum = bkm.geodeticDatum;
    this.physicalMapScale = bkm.physicalMapScale;
    this.otherSource = bkm.otherSource;
    return this;
};

Location.prototype.makeBookmark = function () {
    var bkm = {},
        that = this;
    bkm.decimalLatitude = this.decimalLatitude;
    bkm.decimalLongitude = this.decimalLongitude;
    bkm.locality = this.locality;
    // only add usingRev.. if it is true
    if (this.usingReverseGeocodedLocality === "true") {
        bkm.usingReverseGeocodedLocality = "true";
    }
    $.each(['verbatimLatitude','verbatimLongitude','georeferenceProtocol','geodeticDatum',
        'otherSource'], function (i,prop) {
        if (that[prop] !== "") {
            bkm[prop] = that[prop];
        }
    });
    if (this.georeferenceProtocol === 'physical map') {
        bkm.physicalMapScale = this.physicalMapScale;
    }
    return bkm;
};

Location.prototype.putToScreen = function (options) {
    screenLocation.setLatLng(this.decimalLatitude, this.decimalLongitude, options);
    screenLocation.setSource(this.georeferenceProtocol);
    screenLocation.setUsingReverseGeocodedLocality(this.usingReverseGeocodedLocality);
    // TODO: all the following should be migrated to screenLocation object
    $('#verbatimLatitude').val(this.verbatimLatitude).change();
    $('#verbatimLongitude').val(this.verbatimLongitude).change();
    screenLocation.setLocality(this.locality);
    $('#geodeticDatum').val(this.geodeticDatum).change();
    $('#physicalMap').val(this.physicalMapScale).change();
    $('#otherSource').val(this.otherSource).change();
    return this;
};

Location.prototype.displayLatLng = function () {
    return "Lat:" + this.decimalLatitude + ", Lng:" + this.decimalLongitude;
};

Location.prototype.compare = function (loc) {
    var conflicts = [],
        that = this;
    $.each(['decimalLatitude','decimalLongitude','locality'], function (i, prop) {
        // allow type coercion in the value comparison
        if (hasValue(loc[prop]) && hasValue(that[prop]) && loc[prop] != that[prop]) {
            conflicts.push(prop);
        }
    });
    return conflicts;
};

Location.prototype.isSame = function (loc) {
    var that = this,
        same = true;
    if (loc === undefined || !loc.isValid() || !this.isValid()) {
        return false;
    }
    $.each(['decimalLatitude','decimalLongitude','locality'], function (i, prop) {
        // allow type coercion in the value comparison
        if (loc[prop] != that[prop]) {
            same = false;
        }
    });
    return same;
};

function hasValue(x) {
    return (x !== undefined) && (x !== null) && (x !== "") && (x !== [])
}

/* Manages the current date and time --------------------------------------------------------------- */
var screenDate = {
    dateField: null,
    timeField: null,
    listeners: [],
    init: function () {
        var that = this, date, time;
        this.dateField = $('#date');
        this.timeField = $('#time');

        // catch changes in date and time
        $('#date,#time').change(function () {
            date = that.dateField.val();
            time = that.timeField.val();
            // notify listeners
            $.each(that.listeners, function (i, lis) {
                lis.handler.apply(that, ['dateTimeChange']);
            });
        });
    },
    getAll: function () {
        var dt = new DateTime().loadFromScreen();
        return dt.isValid() ? dt.getEvent() : [];
    },
    getDate: function () {
        return this.dateField.val();
    },
    setDate: function (date, noNotify) {
        this.dateField.val(date);
        if (noNotify !== true) {
            this.dateField.change();
        }
    },
    getTime: function () {
        return this.timeField.val();
    },
    setTime: function (time, noNotify) {
        if (time !== null && time.length > 4) {
            this.timeField.val(time);
            if (noNotify !== true) {
                this.timeField.change();
            }
        }
    },
    isValid: function () {
        return new DateTime().loadFromScreen().isValid();
    },
    isEmpty: function () {
        return this.dateField == null;
    },
    addListener: function(listener) {
        this.listeners.push(listener);
    },
    removeListener: function(listener) {
        this.listeners.remove(listener);
    }
};

/*
Represents any date as a date string in the form 'YYYY', 'YYYY-MM' or 'YYYY-MM-DD'
and a time string in the form 'HH:MM'. A blank/empty time is valid.
 */
function DateTime () {
    this.date = null;
    this.time = null;
    this.verbatimDate = "";
}

DateTime.prototype.isValid = function () {
    return hasValue(this.date);
    // TODO check format of date
    // TODO check format of time
};

DateTime.prototype.storageDateToScreen = function (storageDate) {
    switch (storageDate.length) {
        case 4: return storageDate;  // year only
        case 7: return storageDate.substr(5,2) + '-' + storageDate.substr(0,4);
        case 10: return storageDate.substr(8,2) + '-' + storageDate.substr(5,2) + '-' + storageDate.substr(0,4);
        default: return "";
    }
};

DateTime.prototype.screenDateToStorage = function (screenDate) {
    switch (screenDate.length) {
        case 4: return screenDate;  // year only
        case 7: return screenDate.substr(3,4) + '-' + screenDate.substr(0,2);
        case 10: return screenDate.substr(6,4) + '-' + screenDate.substr(3,2) + '-' + screenDate.substr(0,2);
        default: return "";
    }
};

// screen format id dd-mm-yyyy
DateTime.prototype.getDateForScreen = function () {
    return (this.isValid() ? this.storageDateToScreen(this.date) : "");
};

DateTime.prototype.getTimeForScreen = function () {
    return this.time;//isValid() ? this.time.slice(0,5) : "";
};

// @param date - string in the form dd-mm-yyyy
// @param time - string in the form hh:mm
DateTime.prototype.set = function (date, time) {
    this.date = this.screenDateToStorage(date);
    this.time = time;
    return this;
};

DateTime.prototype.getEvent = function () {
    return {
        eventDate: this.date,
        eventTime: this.time
    }
};

DateTime.prototype.setFromExifFormat = function (dateStr) {
    // exif format example is "2012:03:21 19:51:53"
    if (!dateStr) { return {}; }
    var dt = dateStr.split(' ');
    this.date = dt[0];
    this.time = dt[1];
    // discard seconds
    if (this.time.length > 5) {
        this.time = this.time.slice(0,5);
    }
    this.verbatimDate = dateStr;
    return this;
};

DateTime.prototype.setFromStoredFormat = function (dateStr, timeStr) {
    if (!dateStr) { return {}; }
    this.verbatimDate = dateStr;
    // assume one of YYYY, YYYY-MM, YYYY-MM-DD
    this.date = dateStr;
    if (typeof timeStr !== 'undefined') {
        if (timeStr !== null && timeStr.length >= 5) {
            this.time = timeStr;
        }
    }
    return this;
};

DateTime.prototype.setFromIsoFormat = function (dateStr) {
    // iso format example is "2005-10-22T03:08:18Z"
    // TODO: use a date library
    if (!dateStr) { return {}; }
    if (dateStr.length !== 20) {
        alert("invalid iso date " + dateStr);
        return this;
    }
    var dt = dateStr.split('T');
    this.date = dt[0];
    this.time = dt[1].slice(0,5);
    this.verbatimDate = dateStr;
    return this;
};

DateTime.prototype.loadFromScreen = function () {
    this.date = this.screenDateToStorage(screenDate.getDate());
    this.time = screenDate.getTime();
    return this;
};

DateTime.prototype.putToScreen = function (noNotify) {
    screenDate.setDate(this.getDateForScreen(), noNotify);
    screenDate.setTime(this.getTimeForScreen(), noNotify);
    return this;
};

DateTime.prototype.compare = function (dat) {
    var conflicts = [];
    if (dat.isValid() && this.isValid() && dat.date != this.date) {
        conflicts.push('date');
    }
    if (dat.isValid() && this.isValid() && dat.time != this.time) {
        conflicts.push('time');
    }
    return conflicts;
};

DateTime.prototype.isSame = function (dat) {
    return !(dat === undefined || dat.date != this.date || dat.time != this.time);
};

function numDecimalPlaces (x, dec_sep) {
    var tmp = x.toString(),
        sep = dec_sep || '.';
    if (tmp.indexOf(sep)>-1)
        return tmp.length-tmp.indexOf(sep)-1;
    else
        return 0;
}

function limit (num, places) {
    var max = places || 7;
    if (num !== NaN) {
        if (numDecimalPlaces(num) > max) {
            return num.toFixed(max);
        }
    }
    return num;
}

