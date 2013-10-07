var directionsDisplay;
var directionsService;
var marker;
var geocoder;
var map;
var defaultCenter;
var infowindow;
var center;
var prefix;
var textfield;
var timer;
var currentDirections = null;
var initialLocation;
var helsinki;
var browserSupportFlag =  new Boolean();
var listing_type;
var listing_category = ["all"];
var listing_sharetypes = ["all"];
var listing_tags = [];
var listing_search;
var locale;
var flagMarker;
var markers = [];
var markerContents = [];
var markersArr = [];   // Array for keeping track of markers on map
var showingMarker = "";
var markerCluster = null;

$.validator.
addMethod("address_validator",
  function(value, element, param) {
    var check = null;
  
    // Added to allow empty locations
    if (value == "") {
      return true;
    }
  
    var pref = element.id.split("_");
    var elem_prefix ="";
    if (pref[0].match("person"))
      elem_prefix = "person";
    else if (pref[0].match("community"))
      elem_prefix = "community";
    else
      elem_prefix = pref[0] + "_" + pref[1];

    var emptyfield = $('input[id$="latitude"][id^='+elem_prefix+']').attr("value") || "";

    if(emptyfield != "")
      check = true;
    else
      check = false;

    return check;
  }
);

function timed_input(param) {
  clearTimeout(timer);
  invalid_locations();
  timer=setTimeout(
    function() {
      update_map(param);
    }, 
    1500
  );
}

function timed_input_on_route(){
  clearTimeout(timer);
  invalid_locations("listing_origin_loc_attributes");
  invalid_locations("listing_destination_loc_attributes");
  timer=setTimeout(
    function() {
      startRoute();
    }, 1500
  );
}

function googlemapMarkerInit(canvas,n_prefix,n_textfield,draggable,community_location_lat,community_location_lon,address) {
  prefix = n_prefix;
  textfield = n_textfield;
  
  if (draggable == undefined)
    draggable = false;
    
  var latitude = document.getElementById(prefix+ "_latitude");
  var longitude = document.getElementById(prefix+ "_longitude");
  var visible = true;
  
  var myOptions = {
    'zoom': 12,
    'streetViewControl': false,
    'mapTypeControl': false,
    'mapTypeId': google.maps.MapTypeId.ROADMAP
  }
  
  map = new google.maps.Map(document.getElementById(canvas), myOptions);
  if (latitude.value != "") {
    setMapCenter(latitude.value, longitude.value, false, true);
  } else {
    setMapCenter(community_location_lat, community_location_lon, false, false);
  }
  geocoder = new google.maps.Geocoder();
  
  if (latitude.value != ""){
    markerPosition = new google.maps.LatLng(latitude.value,longitude.value);
  } else {
    markerPosition = defaultCenter;
    visible = false;
  }
  
  marker = new google.maps.Marker({
    'map': map,
    'draggable': draggable,
    'animation': google.maps.Animation.DROP,
    'position': markerPosition
  });

  infowindow = new google.maps.InfoWindow();
  
  if (address != undefined) {
    google.maps.event.addListener(marker, 'click', function() {
      infowindow.close();
      infowindow.setContent(address);
      infowindow.open(map,marker);
    });
  }

  if (draggable){
    google.maps.event.addListener(map, "click", 
      function(event) {
        marker.setPosition(event.latLng);
        marker.setVisible(true);
        geocoder.geocode({"latLng":event.latLng},update_source);
      }
    );
  
    google.maps.event.addListener(marker, "dragend", 
      function() {
        geocoder.geocode({"latLng":marker.getPosition()},update_source);
      }
    );
  }
  
  if(!visible)
    marker.setVisible(false);
}

function update_map(field) {
  if (geocoder) {
    geocoder.geocode({'address':field.value}, 
      function(response,info) {
        if (info == google.maps.GeocoderStatus.OK){
          marker.setVisible(true);
          map.setCenter(response[0].geometry.location);
          marker.setPosition(response[0].geometry.location);
          update_model_location(response);
        } else {
          marker.setVisible(false);
          nil_locations();
        }
      }
    );
  } else {
    return false;
  }
}

function update_source(response,status){
  if (status == google.maps.GeocoderStatus.OK){
    update_model_location(response);
    source = document.getElementById(textfield);
    source.value = response[0].formatted_address;
  } else {
    marker.setPosition(new google.maps.LatLng(60.1894, 24.8358));
    marker.setVisible(false);
    nil_locations();
  }
}

function manually_validate(formhint) {
  var rray = formhint.split("_");
  var form_id = "#";
  var _element = "#";

  if (rray[0].match("person")) {
    form_id += "person_settings_form";
    _element += "person_street_address";
  } else if (rray[0].match("community")) {
    form_id += "new_tribe_form";
    _element += "community_address";
  } else if (rray[0].match("listing")) {
    form_id += "new_listing_form";
    if (rray[1].match("origin")) {
      _element += "listing_origin";
    } else if(rray[1].match("destination")) {
      _element += "listing_destination";
    }
  }
  $(form_id).validate().element(_element);
}

function nil_locations(_prefix) {
  if (!_prefix)
    _prefix = prefix;
  var address = document.getElementById(_prefix+ "_address");
  var latitude = document.getElementById(_prefix+ "_latitude");
  var longitude = document.getElementById(_prefix+ "_longitude");
  var google_address = document.getElementById(_prefix+ "_google_address");
  address.value = null;
  latitude.value = null;
  longitude.value = null;
  google_address.value = null;
  manually_validate(_prefix);
}

// Make validation fail before it has been checked that the
// address is found
function invalid_locations(_prefix) {
  if (!_prefix)
    _prefix = prefix;
  var latitude = document.getElementById(_prefix+ "_latitude");
  latitude.value = null;
}

function update_model_location(place,_prefix){
  if (!_prefix)
    _prefix = prefix;
  var address = document.getElementById(_prefix+ "_address");
  var latitude = document.getElementById(_prefix+ "_latitude");
  var longitude = document.getElementById(_prefix+ "_longitude");
  var google_address = document.getElementById(_prefix+ "_google_address");

  address.value = place[0].formatted_address;
  latitude.value = place[0].geometry.location.lat();
  longitude.value = place[0].geometry.location.lng();
  google_address.value = place[0].formatted_address;
  manually_validate(_prefix);
}



// Rideshare
function googlemapRouteInit(canvas) {

  geocoder = new google.maps.Geocoder();
  directionsService = new google.maps.DirectionsService();
  defaultCenter = new google.maps.LatLng(60.17, 24.94);
  
  var myOptions = {
    'mapTypeId': google.maps.MapTypeId.ROADMAP,
    'disableDefaultUI': false,
    'streetViewControl': false,
    'mapTypeControl': false
  }

  map = new google.maps.Map(document.getElementById(canvas), myOptions);

  var markerOptions = {
    'animation': google.maps.Animation.DROP
  }

  directionsDisplay = new google.maps.DirectionsRenderer({
    'map': map,
    'hideRouteList': true,
    'preserveViewport': false,
    'draggable': false,
    'markerOptions': markerOptions
  });

  google.maps.event.addListener(directionsDisplay, 'directions_changed', 
    function() {
      if (currentDirections) {
        //updateTextBoxes();
      } else {
        currentDirections = directionsDisplay.getDirections();
      }
    }
  );
}


// Use this one for "new" and "edit"
function startRoute(latitude, longitude) {
  var foo = document.getElementById("listing_origin").value;
  var bar = document.getElementById("listing_destination").value;
  directionsDisplay.setMap(map);
  document.getElementById("listing_origin_loc_attributes_address").value = foo;
  document.getElementById("listing_destination_loc_attributes_address").value = bar;

  if(foo != '' && bar != '') {
    calcRoute(foo, bar);
  } else {
    removeRoute();
    if (foo == '' && bar == '') {
      setMapCenter(latitude, longitude, false, true);
      map.setZoom(12);
    }
  }
}

function wrongLocationRoute(field){
  document.getElementById(field).value = "Address not found";
  document.getElementById(field+"_loc_attributes_address").value = null; 
  document.getElementById(field+"_loc_attributes_google_address").value = null; 
  document.getElementById(field+"_loc_attributes_latitude").value = null;
  document.getElementById(field+"_loc_attributes_longitude").value = null;
}

function wipeFieldsRoute(field) {
  document.getElementById(field+"_loc_attributes_address").value = null; 
  document.getElementById(field+"_loc_attributes_google_address").value = null; 
  document.getElementById(field+"_loc_attributes_latitude").value = null;
  document.getElementById(field+"_loc_attributes_longitude").value = null;
}

function removeRoute() {
  directionsDisplay.setMap(null);  
}


// Use this one for "show"
function showRoute(orig, dest) {
  var start = orig;
  var end = dest;
    
  var request = {
    origin:start,
    destination:end,
    travelMode: google.maps.DirectionsTravelMode.DRIVING,
    unitSystem: google.maps.DirectionsUnitSystem.METRIC
  };
  
  directionsService.route(request, function(response, status) {
    if (status == google.maps.DirectionsStatus.OK) {
      directionsDisplay.setDirections(response);
    } 
  });
}

function route_not_found(orig, dest) {
  if (orig) {
    geocoder.geocode( { 'address': orig}, function(response, status){
       if (!(status == google.maps.GeocoderStatus.OK)) {
        nil_locations("listing_origin_loc_attributes");
         removeRoute();
       } else {
        update_model_location(response, "listing_origin_loc_attributes");
      }
    });
  } else { 
    nil_locations("listing_origin_loc_attributes");
  }
  if (dest) {
    geocoder.geocode( { 'address': dest}, function(responce,status){
       if (!(status == google.maps.GeocoderStatus.OK)) {
        nil_locations("listing_destination_loc_attributes");
         removeRoute();
       } else {
        update_model_location(responce, "listing_destination_loc_attributes");
        calcRoute(foo, bar);
      }
    });
  } else {
    nil_locations("listing_destination_loc_attributes");
  }
}

// Route request to the Google API
function calcRoute(orig, dest) {
  var start = orig;
  var end = dest;
  
  if(!orig.match(dest)){

    var request = {
      origin:start,
      destination:end,
      travelMode: google.maps.DirectionsTravelMode.DRIVING,
      unitSystem: google.maps.DirectionsUnitSystem.METRIC
    };
    
    directionsService.route(request, function(response, status) {
      if (status == google.maps.DirectionsStatus.OK) {
         directionsDisplay.setDirections(response);
        updateEditTextBoxes();
      } else {
        removeRoute();
        route_not_found(orig,dest);
      }
    });
  } else {
    removeRoute();
  }
}

function updateEditTextBoxes() {
  var foo = directionsDisplay.getDirections().routes[0].legs[0].start_address;
  var bar = directionsDisplay.getDirections().routes[0].legs[0].end_address;
  document.getElementById("listing_origin_loc_attributes_google_address").value = foo; 
  document.getElementById("listing_destination_loc_attributes_google_address").value = bar;
  document.getElementById("listing_origin_loc_attributes_latitude").value = directionsDisplay.getDirections().routes[0].legs[0].start_location.lat();
  document.getElementById("listing_origin_loc_attributes_longitude").value = directionsDisplay.getDirections().routes[0].legs[0].start_location.lng();
  document.getElementById("listing_destination_loc_attributes_latitude").value = directionsDisplay.getDirections().routes[0].legs[0].end_location.lat();
  document.getElementById("listing_destination_loc_attributes_longitude").value = directionsDisplay.getDirections().routes[0].legs[0].end_location.lng();
  manually_validate("listing_destination");
  manually_validate("listing_origin");
}

function initialize_communities_map() {
  infowindow = new google.maps.InfoWindow();
  helsinki = new google.maps.LatLng(60.2, 24.9);
  flagMarker = new google.maps.Marker();
  var myOptions = {
    zoom: 2,
    center: new google.maps.LatLng(20, 15),
    mapTypeId: google.maps.MapTypeId.ROADMAP
  };
  map = new google.maps.Map(document.getElementById("map-canvas"), myOptions);
  
  
  //map.setCenter(initialLocation);
  google.maps.event.addDomListener(window, 'load', addCommunityMarkers);
  //google.maps.event.addListenerOnce(map, 'tilesloaded', addListingMarkers);
}

function addCommunityMarkers() {
  // Test requesting location data
  // Now the request_path needs to also have a query string with the wanted parameters
  
  markerContents = [];
  markers = [];
  
  var request_path = '/en/tribes'
  $.getJSON(request_path, {dataType: "json"}, function(data) {  
    var data_arr = data.data;
    //alert(data_arr);
      
    for (i in data_arr) {
      (function() {
        var entry = data_arr[i];
        markerContents[i] = entry["id"];
        if (entry["latitude"]) {
          var location;
          location = new google.maps.LatLng(entry["latitude"], entry["longitude"]);
          var marker = new google.maps.Marker({
            position: location,
            title: entry["name"],
            map: map,
            icon: '/assets/dashboard/map_icons/tribe.png'
          });
          markers.push(marker);
          markersArr.push(marker);


          var ind = i;
          google.maps.event.addListener(marker, 'click', function() {
            infowindow.close();
            //directionsDisplay.setMap(null);
            //flagMarker.setOptions({map:null});
            if (showingMarker==marker.getTitle()) {
              showingMarker = "";
            } else {
              showingMarker = marker.getTitle();
              infowindow.setContent("<div id='map_bubble'><div style='text-align: center; width: 360px; height: 70px; padding-top: 25px;'><img src='https://s3.amazonaws.com/sharetribe/assets/ajax-loader-grey.gif'></div></div>");
              infowindow.open(map,marker);
              $.get('/en/tribes/'+entry["id"], function(data) {
                $('#map_bubble').html(data);
              });
            }
          });
          google.maps.event.addListener(infowindow, 'closeclick', function() {
            showingMarker = "";
          });
        }
      })();
    }
      // markerCluster = new MarkerClusterer(map, markers, markerContents, infowindow, showingMarker, {
      //   imagePath: '/assets/map_icons/group_'+listing_type});

  });
}

function initialize_listing_map(community_location_lat, community_location_lon, locale_to_use, use_community_location_as_default) {
  locale = locale_to_use;
  // infowindow = new google.maps.InfoWindow();
  infowindow = new InfoBubble({
    shadowStyle: 0,
    borderRadius: 0,
    borderWidth: 1,
    arrowPosition: 30,
    arrowStyle: 0,
    padding: 0,
    maxHeight: 150,
    maxWidth: 200,
    hideCloseButton: true
  });
  if ($(window).width() >= 768) {
    infowindow.setMinHeight(235);
    infowindow.setMinWidth(425);
  } else {
    infowindow.setMinHeight(150);
    infowindow.setMinWidth(225);
  } 
  directionsService = new google.maps.DirectionsService();
  directionsDisplay = new google.maps.DirectionsRenderer();
  directionsDisplay.setOptions( { suppressMarkers: true } );
  helsinki = new google.maps.LatLng(60.17, 24.94);
  flagMarker = new google.maps.Marker();
  var myOptions = {
    zoom: 13,
    mapTypeId: google.maps.MapTypeId.ROADMAP
  };
  map = new google.maps.Map(document.getElementById("map-canvas"), myOptions);
  var prefer_param_loc = (use_community_location_as_default === 'true');
  setMapCenter(community_location_lat, community_location_lon, true, prefer_param_loc);
  google.maps.event.addListenerOnce(map, 'tilesloaded', addListingMarkers);
}

function setMapCenter(community_location_lat, community_location_lon, show_alerts, prefer_param_loc) {
  
  // Try first parameter location, then browser geolocation, then default position
  if (prefer_param_loc == true) {
    if (community_location_lat != null && community_location_lon != '') {
      map.setCenter(new google.maps.LatLng(community_location_lat,community_location_lon));
    // Browser doesn't support Geolocation, we need to use the default location.
    } else if (navigator.geolocation) {  
      navigator.geolocation.getCurrentPosition(
        function(position) {
          map.setCenter(new google.maps.LatLng(position.coords.latitude,position.coords.longitude));
        }, 
        function() {
          setDefaultMapCenter(map, show_alerts);
        }
      );
    }
  
  // Try first browser geolocation, then parameter location, then default position
  } else {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition( 
        function(position) {
          map.setCenter(new google.maps.LatLng(position.coords.latitude,position.coords.longitude));
        }, 
        function() {
          setParamMapCenter(map, community_location_lat, community_location_lon, show_alerts);
        }
      );
    } else {
      setParamMapCenter(map, community_location_lat, community_location_lon, show_alerts);
    }
  }
  
}

function setParamMapCenter(map, lat, lon, show_alerts) {
  if (lat != null && lon != '') {
    map.setCenter(new google.maps.LatLng(lat,lon));
  } else {
    setDefaultMapCenter(map, show_alerts);
  }
}

function setDefaultMapCenter(map, show_alerts) {
  // Set default location to Helsinki
  var defaultPosition = new google.maps.LatLng(60.17, 24.94);
  if (show_alerts == true)
    alert("Your browser doesn't support geolocation. We've placed you in Helsinki, Finland.");
  map.setCenter(defaultPosition);
}



function addListingMarkers() {
  // Test requesting location data
  // Now the request_path needs to also have a query string with the wanted parameters
  
  markerContents = [];
  markers = [];
  
  var starttime = new Date().getTime();
  var request_path = '/listings/locations_json'
  $.get(request_path, { listing_type: listing_type, 'category[]': listing_category, 'share_type[]': listing_sharetypes, search: listing_search}, function(data) {  

    var data_arr = data.data;
    for (i in data_arr) {
      (function() {
        var entry = data_arr[i];
        markerContents[i] = entry["id"];
        if (entry["latitude"]) {
          
          var location;
          location = new google.maps.LatLng(entry["latitude"], entry["longitude"]);
          
          // Marker background image based on listing_type
          var icon_path, icon_color;
          if (entry["listing_type"] === "request") {
            icon_path = '/assets/map_icons/map_icon_dark_empty.png';
            icon_color = "d7d7d7";
          } else {
            icon_path = '/assets/map_icons/map_icon_light_empty.png';
            icon_color = "6a6a6a";
          }
          var marker = new google.maps.Marker({
            position: location,
            title: entry["title"],
            icon: icon_path        
          });
          
          // Marker icon based on category
          var label = new Label({
                         map: map
                    });
                    label.set('zIndex', 1234);
                    label.bindTo('position', marker, 'position');
                    label.set('text', "<i class='icon " + entry["icon"] + "'></i>");
                    label.set('color', icon_color);
                    //label.bindTo('text', marker, 'position');
          marker.set("label", label);
          markers.push(marker);
          markersArr.push(marker);
          var ind = i;

          google.maps.event.addListener(map, 'mousedown', function() {
            infowindow.close();
          });

          google.maps.event.addListener(marker, 'click', function() {
            infowindow.close();
            directionsDisplay.setMap(null);
            flagMarker.setOptions({map:null});
            if (showingMarker==marker.getTitle()) {
              showingMarker = "";
            } else {
              showingMarker = marker.getTitle();
              infowindow.setContent("<div id='map_bubble'><div style='text-align: center; width: 360px; height: 70px;'><img src='https://s3.amazonaws.com/sharetribe/assets/ajax-loader-grey.gif'></div></div>");
              infowindow.open(map,marker);
              $.get('/' + locale + '/listing_bubble/' + entry["id"], function(data) {
                $('#map_bubble').html(data);
                if (entry["category"]=="rideshare") {
                  var end = new google.maps.LatLng(entry["destination_loc"]["latitude"], entry["destination_loc"]["longitude"]);
                  var request = {
                    origin:location, 
                    destination:end,
                    travelMode: google.maps.DirectionsTravelMode.DRIVING
                  };
                  directionsDisplay.setMap(map);
                  directionsService.route(request, function(response, status) {
                    if (status == google.maps.DirectionsStatus.OK) {
                      directionsDisplay.setDirections(response);
                    }
                  });
                  flagMarker.setOptions({
                    position: end,
                    map: map,
                    icon: '/assets/map_icons/flag_rideshare.png'
                  });
                }
              });
            }
          });
          google.maps.event.addListener(infowindow, 'closeclick', function() {
            showingMarker = "";
          });
        }
      })();
    }
    markerCluster = new MarkerClusterer(map, markers, markerContents, infowindow, showingMarker, {
    imagePath: '/assets/map_icons/group_'+listing_type});
  
  });
}

function clearMarkers() {
    if (markersArr) {
        for (i in markersArr) {
            markersArr[i].setMap(null);
        }
    }
    directionsDisplay.setMap(null);
    flagMarker.setOptions({map:null});
    if (markerCluster) {
        markerCluster.resetViewport(true);
        markerCluster.clearMarkers();
        delete markerCluster;
        markerCluster = null;
    }
    if (markers) {
        for (n in markers) {
            markers[n].setMap(null);
        }
    }
}

function SetFiltersForMap(type, category, sharetypes, search) {
  if (type)       { listing_type = type;               } else { listing_type = "all";}
  if (category)   { listing_category = [category];     } else { listing_category = ["all"];}
  if (sharetypes) { listing_sharetypes = [sharetypes]; } else { listing_sharetypes = ["all"];}
  if (search)     { listing_search = search            } else { listing_search = "";}
  initialize_labels();
}


// Simple callback for passing filter changes to the mapview
function filtersUpdated(category, sharetypes, tags) {
    listing_category = category;
    listing_sharetypes = sharetypes;
    listing_tags = tags;
    clearMarkers();
    addListingMarkers();
}

