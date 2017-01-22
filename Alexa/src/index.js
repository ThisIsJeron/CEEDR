/**
    Copyright 2014-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.

    Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at

        http://aws.amazon.com/apache2.0/

    or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

/**
 * This sample shows how to create a Lambda function for handling Alexa Skill requests that:
 * - Web service: communicate with an external web service to get tide data from NOAA CO-OPS API (http://tidesandcurrents.noaa.gov/api/)
 * - Multiple optional slots: has 2 slots (city and date), where the user can provide 0, 1, or 2 values, and assumes defaults for the unprovided values
 * - DATE slot: demonstrates date handling and formatted date responses appropriate for speech
 * - Custom slot type: demonstrates using custom slot types to handle a finite set of known values
 * - Dialog and Session state: Handles two models, both a one-shot ask and tell model, and a multi-turn dialog model.
 *   If the user provides an incorrect slot in a one-shot model, it will direct to the dialog model. See the
 *   examples section for sample interactions of these models.
 * - Pre-recorded audio: Uses the SSML 'audio' tag to include an ocean wave sound in the welcome response.
 *
 * Examples:
 * One-shot model:
 *  User:  "Alexa, ask Tide Pooler when is the high tide in Seattle on Saturday"
 *  Alexa: "Saturday June 20th in Seattle the first high tide will be around 7:18 am,
 *          and will peak at ...""
 * Dialog model:
 *  User:  "Alexa, open Tide Pooler"
 *  Alexa: "Welcome to Tide Pooler. Which city would you like tide information for?"
 *  User:  "Seattle"
 *  Alexa: "For which date?"
 *  User:  "this Saturday"
 *  Alexa: "Saturday June 20th in Seattle the first high tide will be around 7:18 am,
 *          and will peak at ...""
 */

/**
 * App ID for the skill
 */
var APP_ID = undefined;//replace with 'amzn1.echo-sdk-ams.app.[your-unique-value-here]';

var http = require('http'),
    alexaDateUtil = require('./alexaDateUtil');

/**
 * The AlexaSkill prototype and helper functions
 */
var AlexaSkill = require('./AlexaSkill');

/**
 * TidePooler is a child of AlexaSkill.
 * To read more about inheritance in JavaScript, see the link below.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Introduction_to_Object-Oriented_JavaScript#Inheritance
 */
var Ceedr = function () {
    AlexaSkill.call(this, APP_ID);
};

// Extend AlexaSkill
Ceedr.prototype = Object.create(AlexaSkill.prototype);
Ceedr.prototype.constructor = Ceedr;

// ----------------------- Override AlexaSkill request and intent handlers -----------------------

Ceedr.prototype.eventHandlers.onSessionStarted = function (sessionStartedRequest, session) {
    console.log("onSessionStarted requestId: " + sessionStartedRequest.requestId
        + ", sessionId: " + session.sessionId);
    // any initialization logic goes here
};

Ceedr.prototype.eventHandlers.onLaunch = function (launchRequest, session, response) {
    console.log("onLaunch requestId: " + launchRequest.requestId + ", sessionId: " + session.sessionId);
    handleWelcomeRequest(response);
};

Ceedr.prototype.eventHandlers.onSessionEnded = function (sessionEndedRequest, session) {
    console.log("onSessionEnded requestId: " + sessionEndedRequest.requestId
        + ", sessionId: " + session.sessionId);
    // any cleanup logic goes here
};

/**
 * override intentHandlers to map intent handling functions.
 */
Ceedr.prototype.intentHandlers = {
    "OneshotEnergyIntent": function (intent, session, response) {
        handleOneshotEnergyRequest(intent, session, response);
    },

    "DialogIntent": function (intent, session, response) {
        // Determine if this turn is for city, for date, or an error.
        // We could be passed slots with values, no slots, slots with no value.
        var energySlot = intent.slots.Energy;
        var buildingSlot = intent.slots.Building;
        var dateSlot = intent.slots.Date;
        if (energySlot && energySlot.value && buildingSlot && buildingSlot.value 
                       && dateSlot && dateSlot.value) {
            handleEnergyDialogRequest(intent, session, response);
        } else {
            handleNoSlotDialogRequest(intent, session, response);
        }
    },

    "SupportedCitiesIntent": function (intent, session, response) {
        handleSupportedBuildingsRequest(intent, session, response);
    },

    "AMAZON.HelpIntent": function (intent, session, response) {
        handleHelpRequest(response);
    },

    "AMAZON.StopIntent": function (intent, session, response) {
        var speechOutput = "Goodbye";
        response.tell(speechOutput);
    },

    "AMAZON.CancelIntent": function (intent, session, response) {
        var speechOutput = "Goodbye";
        response.tell(speechOutput);
    }
};

// -------------------------- TidePooler Domain Specific Business Logic --------------------------

function handleWelcomeRequest(response) {
    var whichBuildingPrompt = "Which building would you like energy information for?",
        speechOutput = {
            speech: "<speak>Welcome to Ceedr. "
                + whichBuildingPrompt
                + "</speak>",
            type: AlexaSkill.speechOutputType.SSML
        },
        repromptOutput = {
            speech: "I can lead you through providing a type of energy use "
                + "building and "
                + "date "
                + "or you can simply open Ceedr and ask a question like, "
                + "How much total energy did John D. Kemper Hall of Engineering consume on January 21, 2017?"
            type: AlexaSkill.speechOutputType.PLAIN_TEXT
        };

    response.ask(speechOutput, repromptOutput);
}

function handleHelpRequest(response) {
    var repromptText = "Which energy type would you like energy information for?";
    var speechOutput = "I can lead you through providing a type of energy use "
        + "building and "
        + "date "
        + "or you can simply open Ceedr and ask a question like, "
        + "get electric use for Warren & Leta Giedt Hall for Monday. "
        + "Or you can say exit. "
        + repromptText;

    response.ask(speechOutput, repromptText);
}

/**
 * Handles the case where the user asked or for, or is otherwise being with supported cities
 */
function handleSupportedBuildingsRequest(intent, session, response) {
    // get city re-prompt
    var repromptText = "Which building would you like energy information for?";
    var speechOutput = repromptText;

    response.ask(speechOutput, repromptText);
}

/**
 * Handles the dialog step where the user provides a energy type, building, and date
 */
function handleBuildingDialogRequest(intent, session, response) {

    var buildingLoc = getBuildingFromIntent(intent, false),
        repromptText,
        speechOutput;
    if (buildingLoc.error) {
        repromptText = "Which building would you like energy information for?";
        // if we received a value for the incorrect city, repeat it to the user, otherwise we received an empty slot
        speechOutput = buildingLoc.OfficialName ? "I'm sorry, I don't have any data for " + buildingLoc.OfficialName + ". " + repromptText : repromptText;
        response.ask(speechOutput, repromptText);
        return;
    }

    // if we don't have a date yet, go to date. If we have a date, we perform the final request
    if (session.attributes.date) {
        getFinalEnergyResponse(buildingLoc, session.attributes.date, response);
    } else {
        // set city in session and prompt for date
        session.attributes.building = buildingLoc;
        speechOutput = "For which date?";
        repromptText = "For which date would you like tide information for " + buildingLoc.OfficialName + "?";

        response.ask(speechOutput, repromptText);
    }
}

/**
 * Handles the dialog step where the user provides a date
 */
function handleDateDialogRequest(intent, session, response) {

    var date = getDateFromIntent(intent),
        repromptText,
        speechOutput;
    if (!date) {
        repromptText = "Please try again saying a day of the week, for example, Saturday. "
            + "For which date would you like tide information?";
        speechOutput = "I'm sorry, I didn't understand that date. " + repromptText;

        response.ask(speechOutput, repromptText);
        return;
    }

    // if we don't have a city yet, go to city. If we have a city, we perform the final request
    if (session.attributes.city) {
        getFinalEnergyResponse(session.attributes.city, energy, date, response);
    } else {
        // The user provided a date out of turn. Set date in session and prompt for city
        session.attributes.date = date;
        speechOutput = "For which city would you like tide information for " + date.displayDate + "?";
        repromptText = "For which city?";

        response.ask(speechOutput, repromptText);
    }
}

/**
 * Handle no slots, or slot(s) with no values.
 * In the case of a dialog based skill with multiple slots,
 * when passed a slot with no value, we cannot have confidence
 * it is the correct slot type so we rely on session state to
 * determine the next turn in the dialog, and reprompt.
 */
function handleNoSlotDialogRequest(intent, session, response) {
    if (session.attributes.energy) {
        // get date re-prompt
        var repromptText = "Please try again saying which building, like Peter J. Shields Library. ";
        var speechOutput = repromptText;

        response.ask(speechOutput, repromptText);
    } else {
        // get city re-prompt
        handleSupportedBuildingsRequest(intent, session, response);
    }
}

/**
 * This handles the one-shot interaction, where the user utters a phrase like:
 * 'Alexa, open Tide Pooler and get tide information for Seattle on Saturday'.
 * If there is an error in a slot, this will guide the user to the dialog approach.
 */
function handleOneshotTideRequest(intent, session, response) {
    var energy = getEnergyFromIntent(intent, true),
        repromptText,
        speechOutput;
    if (energy.error) {
        repromptText = "What type of energy would you like information for?";
        speechOutput = energy.value ? "I'm sorry, I don't have any data for " + energy.value + ". " + repromptText : repromptText;
        respone.ask(speechOutput, repromptText);
        return
    }

    // Determine city, using default if none provided
    var building = getBuildingStationFromIntent(intent, true),
    if (!building) {
        // invalid city. move to the dialog
        repromptText = "Which building would you like energy information for?";
        // if we received a value for the incorrect city, repeat it to the user, otherwise we received an empty slot
        speechOutput = building.OriginalName ? "I'm sorry, I don't have any data for " + buildingLoc.OriginalName + ". " + repromptText : repromptText;
        response.ask(speechOutput, repromptText);
        return;
    }

    // Determine custom date
    var date = getDateFromIntent(intent);
    if (!date) {
        // Invalid date. set city in session and prompt for date
        session.attributes.building = buildingLoc;
        repromptText = "Please try again saying a date, for example, March 14. "
            + "For which date would you like tide information?";
        speechOutput = "I'm sorry, I didn't understand that date. " + repromptText;
        response.ask(speechOutput, repromptText);
        return;
    }

    // all slots filled, either from the user or by default values. Move to final request
    getFinalEnergyResponse(buildingStation, date, energy, response);
}

/**
 * Both the one-shot and dialog based paths lead to this method to issue the request, and
 * respond to the user with the final answer.
 */
function getFinalEnergyResponse(buildingLoc, date, response) {

    // Issue the request, and respond to the user
    makeEnergyRequest(energy, buildingLoc, date, function energyResponseCallback(err, energyResponse) {
        var speechOutput;

        if (err) {
            speechOutput = "Sorry, we are experiencing a problem. Please try again later";
        } else {
            speechOutput = buildingLoc.OriginalName + " used " + energy.value + " kBtu on " + date.displayDate;
        }

        response.tellWithCard(speechOutput, "Ceedr", speechOutput)
    });
}

function getObjects(obj, key, val) {
    var retv = [];

    if(jQuery.isPlainObject(obj))
    {
        if(obj[key] === val) // may want to add obj.hasOwnProperty(key) here.
            retv.push(obj);

        var objects = jQuery.grep(obj, function(elem) {
            return (jQuery.isArray(elem) || jQuery.isPlainObject(elem));
        });

        retv.concat(jQuery.map(objects, function(elem){
            return getObjects(elem, key, val);
        }));
    }

    return retv;
}

/**
 * Uses NOAA.gov API, documented: http://tidesandcurrents.noaa.gov/api/
 * Results can be verified at: http://tidesandcurrents.noaa.gov/noaatidepredictions/NOAATidesFacade.jsp?Stationid=[id]
 */
function makeEnergyRequest(energy, building, date, energyResponseCallback) {

    //var datum = "MLLW";

    var endpoint = 'https://bldg-pi-api.ou.ad3.ucdavis.edu/piwebapi/streams/';
    queryString += getObjects();
    queryString += '/interpolated';

    http.get(endpoint + queryString, function (res) {
        var noaaResponseString = '';
        console.log('Status Code: ' + res.statusCode);

        if (res.statusCode != 200) {
            energyResponseCallback(new Error("Non 200 Response"));
        }

        res.on('data', function (data) {
            noaaResponseString += data;
        });

        res.on('end', function () {
            var noaaResponseObject = JSON.parse(noaaResponseString);

            if (noaaResponseObject.error) {
                console.log("NOAA error: " + noaaResponseObj.error.message);
                energyResponseCallback(new Error(noaaResponseObj.error.message));
            } else {
                var highTide = findHighTide(noaaResponseObject);
                energyResponseCallback(null, highTide);
            }
        });
    }).on('error', function (e) {
        console.log("Communications error: " + e.message);
        energyResponseCallback(new Error(e.message));
    });
}

/**
 * Gets the city from the intent, or returns an error
 */
function getBuildingStationFromIntent(intent, assignDefault) {

    var buildingSlot = intent.slots.Building;
    // slots can be missing, or slots can be provided but with empty value.
    // must test for both.o
    if (!buildingSlot || !buildingSlot.OriginalName) {
        if (!assignDefault) {
            return {
                error: true
            }
    } else {
        // lookup the city. Sample skill uses well known mapping of a few known cities to station id.
        var buildingName = buildingSlot.Original;
            return {
                building: buildingName,
            }
        } else {
            return {
                error: true,
                building: buildingName
            }
        }
    }
}

/**
 * Gets the date from the intent, defaulting to today if none provided,
 * or returns an error
 */
function getDateFromIntent(intent) {

    var dateSlot = intent.slots.Date;
    // slots can be missing, or slots can be provided but with empty value.
    // must test for both.
    if (!dateSlot || !dateSlot.value) {
        // default to today
        return {
            displayDate: "Today",
            requestDateParam: "date=today"
        }
    } else {

        var date = new Date(dateSlot.value);

        // format the request date like YYYYMMDD
        var month = (date.getMonth() + 1);
        month = month < 10 ? '0' + month : month;
        var dayOfMonth = date.getDate();
        dayOfMonth = dayOfMonth < 10 ? '0' + dayOfMonth : dayOfMonth;
        var requestDay = "begin_date=" + date.getFullYear() + month + dayOfMonth
            + "&range=24";

        return {
            displayDate: alexaDateUtil.getFormattedDate(date),
            requestDateParam: requestDay
        }
    }
}


// Create the handler that responds to the Alexa Request.
exports.handler = function (event, context) {
    var ceedr = new Ceedr();
    ceedr.execute(event, context);
};
