window.addEventListener('load', pageLoad, false);

//Defining here to make available to everyone
var model;
var controller;

function pageLoad() {
    //Initialize stuff
    controller = new Controller();
    model = new Model();
    model.finishLoad(startLoadGame);

    if (navigator.appName == 'Microsoft Internet Explorer') alert('You might need to install quicktime to properly view some media.\n(http://www.apple.com/quicktime/download)');
}

function startLoadGame() {
    startSift('top');
}


function finishLoadGame(responseData) {
    if (responseData.returnCode == 1) //Error
    {
        document.getElementById('messageContent').innerHTML = responseData.data;
        return;
    }
    model.populateFromData(responseData.data);


    controller.populateAllFromModel();

    //  Set actual page visible
    document.getElementById('messageContent').innerHTML = "";
    document.getElementById('message').style.display = 'none';

    google.maps.event.trigger(model.views.gmap, 'resize'); // To fix google maps incorrect sizing bug

}

function siftMore() {
    model.howMany += 50;
    startSift(model.lastSiftType, model.howMany);
}

function startSift(siftType, howMany) {
    if (howMany === undefined) howMany = 50;
    model.howMany = howMany;
    model.lastSiftType = siftType;

    model.views.mainViewLeft.innerHTML = ''; //clear out old notes
    document.getElementById('messageContent').innerHTML = "Sifting...";
    document.getElementById('message').style.display = 'block'; //this is set to hidden after page loads first time

    //we remember this in model so that on tag or searchs we can retrieve the last used sift
    var searchTypeCode = model.getSiftTypeCode(siftType);

    //check to see if any search terms have been set, if so, build an array by word
    var searchTerms = $('.sifter-filter-search-input').filter(":visible").val().split(" ");
    if (searchTerms[0] === "") {
        searchTerms = [];
    }

    //see which tags have been set and put their id #s in the selectedTags array
    var selectedTags = [];
    for (var i = 1; i <= model.tags.length; i++) {
        tagItem = document.getElementById("tag" + i);
        if (tagItem.checked) {

            //each tag has an ID number, which must be sent to the JSON for the query to work right
            var tagIdNum;
            switch (tagItem.value.toLowerCase().trim()) {
                case model.tags[0].tag.toLowerCase().trim():
                    tagIdNum = model.tags[0].tag_id;
                    break;
                case model.tags[1].tag.toLowerCase().trim():
                    tagIdNum = model.tags[1].tag_id;
                    break;
                case model.tags[2].tag.toLowerCase().trim():
                    tagIdNum = model.tags[2].tag_id;
                    break;
                case model.tags[3].tag.toLowerCase().trim():
                    tagIdNum = model.tags[3].tag_id;
                    break;
                case model.tags[4].tag.toLowerCase().trim():
                    tagIdNum = model.tags[4].tag_id;
                    break;
            }
            //tag ids are below,but pull from array for safety
            //innovation dev 117 prod 1404
            //must do dev 118 prod 1413
            //madison Culture dev 119 prod 1410
            //stories of the past dev 120 prod 1407
            //100 years form now dev 121 prod 1414
            selectedTags[selectedTags.length] = tagIdNum;
        }
    }

    var siftObj = {
        game_id: model.gameId,
        search_terms: searchTerms,
        note_count: howMany,
        tag_ids: selectedTags,
        order_by: 'recent',
    };
    switch (siftType) {
        case "popular":
            siftObj.order_by = 'popular';
            break;
        case "mine":
            siftObj.user_id = model.playerId;
            break;
        case "top":
        case "recent":
        case "tags":
        case "search":
            break;
        default:
            console.log("Error in sift type: " + siftType);
    }
    callService2("notes.searchNotes", finishLoadGame, '', JSON.stringify(siftObj));
}
