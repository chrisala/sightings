<!DOCTYPE HTML>
<html xmlns="http://www.w3.org/1999/html">
<head>
    <title>Report a sighting | Atlas of Living Australia</title>
    <meta name="layout" content="ala" />
    <link rel="stylesheet" href="//ajax.googleapis.com/ajax/libs/jqueryui/1.9.2/themes/smoothness/jquery-ui.css" type="text/css" media="screen" />
    <!-- Shim to make HTML5 elements usable in older Internet Explorer versions -->
    <!--[if lt IE 9]><script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
    <script src="//maps.google.com/maps/api/js?key=AIzaSyDBSZ8E9ZCWUULo8Us31Zxhm9u3AWLuHGw&sensor=false&libraries=drawing"></script>
    <script src="//code.jquery.com/ui/1.9.2/jquery-ui.js"></script>
    <!-- App specific styles -->
    <r:script disposition="head">
        var serverUrl = "${grailsApplication.config.grails.serverURL}",
            bieUrl = "${grailsApplication.config.bie.baseURL}",
            userId = "${userId}",
            guid = "${guid}",
            recordsServerUrl = "${createLink(controller: 'proxy', action: 'submitRecord')}",
            bookmarkServerUrl = "${grailsApplication.config.ala.locationBookmarkServerURL}",
            deleteImageUrl = "${resource(dir:'images/ala',file:'delete.png')}";
            simulateError = "${simulateError}";
    </r:script>
    <r:require module="application"/>
    <r:require module="upload"/>
    <r:require module="jQueryImageUpload"/>
    %{--<r:require module="jQueryUI"/>--}%
    <r:require module="jQueryCookie"/>
    <r:require module="jQueryTimeEntry"/>
    <r:require module="exif"/>
    <r:require module="maskedInput"/>
    <r:require module="jqueryValidationEngine"/>
    <r:layoutResources/>
</head>
<body>
<div class="inner">
    <div class="page-header">
        <h1>Report a sighting</h1>
        <div id="auth-error"></div>
        %{--<p><g:if test="${userId == ''}">User id missing!!</g:if>
            <g:else>${userId}</g:else></p>--}%
        <p class="hint">Hint: If you are submitting images, select them first and we will try to pre-load the date
        and location fields from the image metadata. See the <g:link target="_blank" action="faq">FAQ</g:link> for help.</p>

        <div style="float:right;padding-right: 45px;">
           <span style="text-align: right;">
                <g:link mapping="mine" class="showMySightings">My sightings</g:link>
                |
                <g:link mapping="recent" class="showRecentSightings">Recent sightings</g:link>
           </span>
        <button type="button" id="submit">Submit record</button>
        </div>
    </div>
    <form id="forValidationOnly">
    <!-- WHAT -->
    <div class="heading ui-corner-left"><h2>What</h2><r:img uri="/images/what.png"/></div>
    <section class="sightings-block ui-corner-all">
        <a href="http://bie.ala.org.au/species/${guid}" target="_blank">
            <img title="Click to show profile" id="taxonImage" class="taxon-image ui-corner-all" src="${imageUrl}" style="display:${imageUrl?'inline':'none'};"/>
        </a>
        <div class="left ${guid?'':'hidden'}" id="taxonBlock" style="width:53%;padding-top:15px;">
            <a href="#" title="Click to show profile" class="scientificName" id="scientificName" target="_blank"></a>
            <span class="commonName" id="commonName">${commonName}</span>
            <div style="padding-top:10px;">
                <div style="float:left;padding-right:20px;"><label for="count">Number seen</label>
                    <g:textField name="count" class="smartspinner" value="1" size="7"
                          data-validation-engine="validate[custom[integer], min[1]]"/></div>
                <div style="float:left;"><label for="identificationVerificationStatus">Confidence in identification</label>
                    <g:select from="['Confident','Uncertain']" name="identificationVerificationStatus" value="1"/></div>
            </div>
        </div>
        <div class="left" style="width:35%;">
            <p class="${guid?'':'hidden'}" id="changeTaxonText">Not the right species? To change identification, type a scientific or common name into
            the box below and choose from the auto-complete list.</p>
            <p class="${guid?'hidden':''}" id="chooseTaxonText">Type a scientific or common name into the box below and choose from the auto-complete list.</p>
            <input type="text" value="" id="taxa" name="taxonText" class="name_autocomplete ac_input" style="width:75%" autocomplete="off">
            <input type="hidden" name="lsid" id="lsid" value="${guid}">
            <button class="ui-state-disabled ${guid?'':'hidden'}" type="button" id="undoTaxon" disabled="disabled">Undo</button>
        </div>
    </section>
    <!-- WHEN -->
    <div class="heading ui-corner-left"><h2>When</h2><r:img uri="/images/when.png"/></div>
    <section class="sightings-block ui-corner-all">
        <div class="left" style="margin-top: 10px;width:40%;">
            <p><label for="date">Date</label> <input type="text" id="date" class="datepicker"
            data-validation-engine="validate[custom[ddMMyyyy]]"></p>
            <p>Click in the date field to pick from a calendar or just type in the date in
            dd-mm-yyyy format.</p>
        </div>
        <div class="left" style="margin-top: 10px;margin-left:30px;width:54%;">
            <p><label for="time">Time</label>
            <input type="text" id="time" size="5"
                   data-validation-engine="validate[custom[time]]"/></p>
            <p>Type in the time (hh:mm 24hr clock) or leave blank if you wish.</p>
        </div>
    </section>
    <!-- WHERE -->
    <div class="heading ui-corner-left"><h2>Where</h2><r:img uri="/images/where.png"/></div>
    <section class="sightings-block ui-corner-all">
        <div class="left" id="location-container">
            <div class="left">
                <label for="location" style="vertical-align:top;">Type in a description of the location.</label><br/>
                <g:textArea class="left" name="location" rows="5" cols="30"/>
            </div>
            <div class="left" id="symbol">
                <span id="reverseLookup" class="symbol" title="Lookup coordinates from description">&raquo;</span><br/>
                <span id="lookup" class="symbol" title="Lookup description from coordinates">&laquo;</span><br/>
                <span id="isLookedUp" class="lookup" title="Locks the description preventing updates as the map pin is dragged">lock</span><br/>
            </div>
            <div style="clear:both;">
                <label for="locationBookmarks" class="minor">Choose from a bookmarked location.</label><br/>
                <g:select name="locationBookmarks" from="['Loading bookmarks..']"
                 keys="['loading']" noSelection="[null:'-- bookmarked locations --']"/>
                <button type="button" id="saveBookmarkButton">Bookmark current location</button>
                <button type="button" id="manageBookmarksButton">Manage bookmarks</button>
            </div>
        </div>
        <div class="left" id="coordinate-container">
            <span>Enter coordinates (decimal degrees) if you already have them.</span><br/>
            <label for="latitude">Latitude</label><g:textField name="latitude" size="17"
                data-validation-engine="validate[funcCall[validateLatLng],condRequired[longitude]]"
                data-errormessage-value-missing="Latitude is required if you enter a longitude."/>
            &nbsp;&nbsp;
            <label for="longitude">Longitude</label><g:textField name="longitude" size="17"
                data-validation-engine="validate[funcCall[validateLatLng],condRequired[latitude]]"
                data-errormessage-value-missing="Longitude is required if you enter a latitude."/><br/>
            <label for="coordinateUncertaintyInMeters">Accuracy (metres)</label><g:textField name="coordinateUncertaintyInMeters"
                data-validation-engine="validate[custom[number], min[.001]]"
                data-errormessage="Must be a positive number" size="17"/><br/>
            <g:hiddenField name="verbatimLatitude"/>
            <g:hiddenField name="verbatimLongitude"/>
            <label for="georeferenceProtocol">What is the source of these coordinates?</label>
            <g:select name="georeferenceProtocol" from="['Google maps','Google earth','GPS device','camera/phone','physical map','other']"/><br/>
            <div id="precisionFields">
                <span id="geodeticDatumField" class="ui-helper-hidden"><label for="geodeticDatum">Enter the geodetic datum for your device</label>
                    <g:select name="geodeticDatum" from="['WGS84','GDA94','AGD 1966','AGD 1984','other','unknown']"/>
                    <r:img id="datumOpener" class="help" uri="/images/question_mark.jpg"/>
                </span>
                <span id="physicalMapScaleField" class="ui-helper-hidden"><label for="physicalMapScale">Enter the scale of the map</label>
                <g:select name="physicalMapScale" from="${physicalMapScales}"/></span>
                <span id="otherSourceField" class="ui-helper-hidden"><label for="otherSource">Enter the source</label>
                <g:textField name="otherSource" data-validation-engine="validate[funcCall[validateOtherSource]]"/></span>

            </div>
            <button type="button" id="main-map-link">Locate on a map</button>
        </div>
        <div class="right" id="small-map-container">
            %{--<span>Or click the map to locate.</span>--}%
            <div id="small-map"></div>
        </div>
        <section style="clear: both;">
            <div id="main-map-container">
                <div id="main-map" style="float: left;"></div>
                <div id="map-sidebar">
                    <button type="button" id="centerOnPin">Centre map on current pin</button>
                    <button type="button" id="pinToCenter">Move pin to centre of map</button>
                    <button type="button" id="showOz">Show whole of Australia</button>
                    <button type="button" id="zoomPin">Zoom into pin</button>
                    <button type="button" id="showWorld">Show world</button>
                    %{--<button type="button" id="discardPin">Discard pin</button>--}%
                    <div id="markers" style="position:absolute; top:360px; left:750px; width:200px; height:100px;">
                        <div id="m1" class="drag" style="position:absolute; left:0; width:32px; height:32px;">
                            <img src="http://maps.gstatic.com/mapfiles/ms/icons/red-dot.png" width="32" height="32" alt="" />
                        </div>
                    </div>
                    <p>Drag the pin onto the map in the rough area of your location. The map will zoom in so you can
                    drag the pin to the exact location.</p>
                </div>
            </div>
        </section>
    </section>
    </form>
    <!-- MEDIA -->
    <div class="heading ui-corner-left"><h2>Media</h2><r:img uri="/images/media.png"/></div>
    <section class="sightings-block ui-corner-all">
        <label for="addImageButtonLarge">Use the button to select one or more images or drag and drop your images into this page.</label>

    <!-- The file upload form used as target for the file upload widget -->
    <g:form name="fileupload" controller="image" action="upload" method="POST" enctype="multipart/form-data">
        <!-- The fileupload-buttonbar contains buttons to add/delete files and start/cancel the upload -->
        <div class="fileupload-buttonbar">
            <div%{-- class="span7"--}%>
                <!-- The fileinput-button span is used to style the file input field as button -->
                <span class="btn btn-success fileinput-button">
                    <i class="icon-plus icon-white"></i>
                    <button type="button" id="addImageButtonLarge">
                        <img src="${resource(dir:'images/ala',file:'add-image-4.png')}"/><br/>
                        <span>Add images</span>
                    </button>
                    <button type="button" id="addImageButtonSmall" style="display: none;">
                        <span>Add more images</span>
                    </button>
                    <input type="file" name="files" id="files" multiple>
                </span>
                <span id="autoUseContainer">
                    <input type="checkbox" id="autoUse">
                    <label for="autoUse">Always use the information embedded in selected photos.</label>
                </span>
                %{--<button type="submit" class="btn btn-primary start">
                    <i class="icon-upload icon-white"></i>
                    <span>Start upload</span>
                </button>
                <button type="reset" class="btn btn-warning cancel">
                    <i class="icon-ban-circle icon-white"></i>
                    <span>Cancel upload</span>
                </button>
                <button type="button" class="btn btn-danger delete">
                    <i class="icon-trash icon-white"></i>
                    <span>Delete</span>
                </button>
                <input type="checkbox" class="toggle">--}%
            </div>
            <!-- The global progress information -->
            <div class="span5 fileupload-progress fade">
                <!-- The global progress bar -->
                <div class="progress progress-success progress-striped active">
                    <div class="bar" style="width:0%;"></div>
                </div>
                <!-- The extended global progress information -->
                <div class="progress-extended">&nbsp;</div>
            </div>
        </div>
        <!-- The loading indicator is shown during file processing -->
        %{--<div class="fileupload-loading"></div>
        <br>--}%
        <!-- The table listing the files available for upload/download -->
        <table id="filesTable" class="table table-striped"><tbody class="files" data-toggle="modal-gallery" data-target="#modal-gallery"></tbody></table>
    </g:form>
    <br/>

    <label for="imageLicence">Licence:</label>
    <g:select name="imageLicence" id="imageLicence" from="['Creative Commons Attribution', 'Creative Commons Attribution-Noncommercial', 'Creative Commons Attribution-Share Alike', 'Creative Commons Attribution-Noncommercial-Share Alike']"/>

    </section>
    <!-- NOTES -->
    <div class="heading ui-corner-left"><h2>Notes</h2><r:img uri="/images/notes.png"/></div>
    <section class="sightings-block ui-corner-all">
        <label for="occurrenceRemarks">Notes</label><g:textArea name="occurrenceRemarks" rows="8" cols="80"/>
    </section>
    <section style="clear:both; padding:20px 0 0 340px;">
        <button type="button" id="alt-submit">Submit record</button>
    </section>
</div>
<!-- modal-gallery is the modal dialog used for the image gallery -->
<div id="modal-gallery" class="modal modal-gallery hide fade" data-filter=":odd">
    <div class="modal-header">
        <a class="close" data-dismiss="modal">&times;</a>
        <h3 class="modal-title"></h3>
    </div>
    <div class="modal-body"><div class="modal-image"></div></div>
    <div class="modal-footer">
        <a class="btn modal-download" target="_blank">
            <i class="icon-download"></i>
            <span>Download</span>
        </a>
        <a class="btn btn-success modal-play modal-slideshow" data-slideshow="5000">
            <i class="icon-play icon-white"></i>
            <span>Slideshow</span>
        </a>
        <a class="btn btn-info modal-prev">
            <i class="icon-arrow-left icon-white"></i>
            <span>Previous</span>
        </a>
        <a class="btn btn-primary modal-next">
            <span>Next</span>
            <i class="icon-arrow-right icon-white"></i>
        </a>
    </div>
</div>
<!-- Dialogs -->
<div id="datumDialog" title="Geodetic datum" class="ui-helper-hidden">
    <p>For coordinates to be correctly interpreted we must also know the spatial reference system
    under which they were collected. Many GPS devices (as well as Google maps) use WGS84. The Australian standard GDA94 is
    virtually identical. Coordinates collected under other standards must be transformed to achieve the best accuracy.</p>
</div>
<div id="dmsConvertDialog" title="Use decimal degrees" class="ui-helper-hidden">
    <p>Coordinates must be entered as decimal degrees, eg -35.7629.</p>
    <p>The values you have entered look like they may be in <strong>degrees, minutes and seconds</strong>. The following
    table shows how we have interpreted them. You can correct the values. The decimal equivalents will be updated
    automatically.</p>
    <table>
        <thead><tr><td></td><td>Entered</td><td>Degrees</td><td>Minutes</td><td>Seconds</td></tr></thead>
        <tr>
            <td>Lat:</td>
            <td id="enteredLat"></td>
            <td><input type="text" id="degreesLat"/></td>
            <td><input type="text" id="minutesLat"/></td>
            <td><input type="text" id="secondsLat"/></td>
        </tr>
        <tr>
            <td>Lng:</td>
            <td id="enteredLng"></td>
            <td><input type="text" id="degreesLng"/></td>
            <td><input type="text" id="minutesLng"/></td>
            <td><input type="text" id="secondsLng"/></td>
        </tr>
    </table>
    <p>The decimal equivalents are:</p>
    <p>Lat: <strong><span id="decLat"></span></strong><br>Lng: <strong><span id="decLng"></span></strong></p>
    <p>Do you want to use these converted values?</p>
</div>
<div id="serverError" title="Oops!" class="dialog ui-helper-hidden">
    <p>We're sorry but there was a problem submitting your record.</p>
    <p>The server may be temporarily unavailable or there may be an unexpected issue with the data or image you are
    submitting. We have logged the failure and it will be investigated in due course.</p>
    <p>Please try again if this
    is the first time the problem has occurred. If you still cannot submit successfully we would really appreciate you
    letting us know at <a href="mailto:support@ala.org.au?subject=Problem%20submitting%20a%20record">support@ala.org.au</a>.
    Please tell us when you had the
    problem (this makes it easier for us to find the incident in the logs) and what you were trying to do. A screenshot of the
    page just before you submit is very useful, or just list the data that you had entered. If you uploaded any images
    please attach these to the email. We are working hard to make this process robust so your help is valuable to us.</p>
    <p><span class="link under" id="showFullError">Show the raw error</span> </p>
    <p id="fullError" class="ui-helper-hidden"></p>
</div>
<div id="locationUpdateDialog" class="dialog ui-helper-hidden">
    <p>The image you just selected contains embedded location information that is different to the values already entered.</p>
    <p>The location embedded in the image is:<br/> lat = <span id="imageLat"></span>, lng = <span id="imageLng"></span></p>
    <p>A Google lookup places this at:<br/> <span id="lookupLocality"></span></p>
    <p>Do you want to use the location from this image?</p>
</div>
<div id="dateUpdateDialog" class="dialog ui-helper-hidden">
    <p>The image you just selected contains an embedded timestamp that is different to the date and time already entered.</p>
    <table>
        <tr><th></th><th>Current value</th><th>This image</th></tr>
        <tr><td>Date and time</td><td id="currentDateTime"></td><td id="imageDateTime"></td></tr>
    </table>
    <p>Do you want to use the image date and time?</p>
</div>
<div id="manageBookmarksDialog" class="dialog ui-helper-hidden" title="Manage your location bookmarks">
    <div><ul id="bookmarksList"></ul></div>
    <div><button type="button" class="small" id="deleteAllBookmarksButton">Delete all bookmarks</button></div>
</div>
<div id="confirmationDialog" class="dialog ui-helper-hidden">
    <p></p>
</div>
<div id="messageDialog" class="dialog ui-helper-hidden">
    <p></p>
</div>
<!-- The template to display files available for upload -->
<script id="template-upload" type="text/x-tmpl">
    {% for (var i=0, file; file=o.files[i]; i++) { %}
    <tr class="template-upload fade">
        <td class="preview"><span class="fade"></span></td>
        <td class="name"><b><span class="name">{%=file.name%}</span></b><br/><span>{%=o.formatFileSize(file.size)%}</span></td>
        {% if (file.error) { %}
        <td class="error" colspan="2"><span class="label label-important">{%=locale.fileupload.error%}</span> {%=locale.fileupload.errors[file.error] || file.error%}</td>
        {% } else if (o.files.valid && !i) { %}
        %{--<td>
            <div class="progress progress-success progress-striped active"><div class="bar" style="width:0%;"></div></div>
        </td>--}%
        <td class="imageDate">
            Date image was captured:<br/>
            <span class="imageDateTime">{%=file.date%}</span><br/>
            <button type="button" class="useImageDate" disabled="disabled">Use this date</button>
        </td>
        <td class="imageLocation">
            Location image was captured:<br/>
            <span class="imageLatLng">Not available</span><br/>
            <button type="button" class="useImageLocation" disabled="disabled">Use this location</button>
        </td>
        <td class="imageInfo">
            Use all info<br/>from this image<br/>
            <button type="button" class="useImageInfo" disabled="disabled">Use both</button>
        </td>
        <td class="start">{% if (!o.options.autoUpload) { %}
            %{--<button class="btn btn-primary">
                <i class="icon-upload icon-white"></i>
                <span>{%=locale.fileupload.start%}</span>
            </button>--}%
            {% } %}</td>
        {% } else { %}
        <td colspan="2"></td>
        {% } %}
        <td class="cancel">{% if (!i) { %}
            %{--<button class="btn btn-warning">
                <i class="icon-ban-circle icon-white"></i>
                <span>{%=locale.fileupload.cancel%}</span>
            </button>--}%
            {% } %}</td>
    </tr>
    {% } %}
</script>
<!-- The template to display files available for download -->
<script id="template-download" type="text/x-tmpl">
    {% for (var i=0, file; file=o.files[i]; i++) { %}
    <tr class="template-download fade">
        {% if (file.error) { %}
        <td></td>
        <td class="name"><b><span class="name">{%=file.name%}</span></b><br/><span>{%=o.formatFileSize(file.size)%}</span></td>
        <td class="error" colspan="2"><input type="text" style="width:5px; visibility:hidden" value="error" data-validation-engine="validate[funcCall[imageHasError]]"><span class="label label-important">{%=locale.fileupload.error%}</span> {%=locale.fileupload.errors[file.error] || file.error%}</td>
        {% } else { %}
        <td class="preview">{% if (file.thumbnail_url) { %}
            <a href="{%=file.url%}" title="{%=file.name%}" rel="gallery" download="{%=file.name%}"><img src="{%=file.thumbnail_url%}"></a>
        {% } %}</td>
        <td class="name"><b><span class="name">{%=file.name%}</span></b><br/><span>{%=o.formatFileSize(file.size)%}</span></td>
        <td class="imageDate">
            Date image was captured:<br/>
            <span class="imageDateTime">
                <span class="imageDate">{%=file.date%}</span>
                <span class="imageTime">{%=file.time%}</span>
            </span><br/>
            <button type="button" class="useImageDate" disabled="disabled">Use this date</button>
            <input type="hidden" class="imageDateISO8601" value="{%=file.isoDate%}"/>
        </td>
        <td class="imageLocation">
            Location image was captured:<br/>
            <span class="imageLatLng">{% if (file.decimalLatitude) { %}
                Lat: <span class="lat">{%=file.decimalLatitude%}</span>,
                Lng: <span class="lng">{%=file.decimalLongitude%}</span>
            {% } else { %}
                Not available
            {% } %}
            </span><br/>
            <button type="button" class="useImageLocation" disabled="disabled">Use this location</button>
            <input type="hidden" class="imageVerbatimLatitude" value="{%=file.verbatimLatitude%}"/>
            <input type="hidden" class="imageVerbatimLongitude" value="{%=file.verbatimLongitude%}"/>
        </td>
        <td class="imageInfo">
            Use all info<br/>from this image<br/>
            <button type="button" class="useImageInfo" disabled="disabled">Use both</button>
        </td>
        {% } %}
        <td class="delete">
            <button class="btn btn-danger" data-type="{%=file.delete_type%}" data-url="{%=file.delete_url%}">
                <i class="icon-trash icon-white"></i>
                <span>{%=locale.fileupload.destroy%}</span>
            </button>
        </td>
    </tr>
    {% } %}
</script>
<r:script>
    // init maps after page load - doing this on the jQuery ready event caused Firefox to never complete loading
    $(window).load(initMaps);
    logToServer('userId: ' + userId, 'debug');
    // protect against sporadic CAS errors
    if (userId == '' || userId == 'null') {
        // we have a problem
        logToServer('userId not available. url is ' + document.location.href, 'error');
        // try redirecting to full path if we are at root (/)
        if (document.location.href !== serverUrl + '/upload/index') {
            document.location.href = serverUrl + '/upload/index';
        }
        // if still here we have a big problem
        $('#auth-error').html("We seem to have failed to recognise your login. Submissions" +
        " will fail in this state. Please try logging out and back in. If that fails please contact" +
        " us at <a href='mailto:support.ala.org.au'>support.ala.org.au</a>.");
    }
</r:script>
<r:layoutResources/>
</body>
</html>
