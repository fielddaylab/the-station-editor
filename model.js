function Model()
{
	self = this;
    //this.gameId = YOI_GAME_ID;
    this.gameId = YOI_GAME_ID;
	this.displayName = ""; //CDH for displaying newly added content
    this.gameJSONText = '';
    //this.gameData = {};
    //this.backpacks = [];
    //this.notes = [];
	this.gameNotes = []; //this is using new API
    this.currentNote = {};
    this.currentNote.noteId = 0;
    this.audio_context = '';
    this.recorder = '';
	this.contentWaitingToUpload = 0; //CDH when user uploads multiple contents, you'll have to wait till all are uploaded before you can push it to HTML
    this.mapMarkers = [];

	self.playerId = 0;
	
	//check to see if they have a session cookie with their playerId and can skip login, if not set it to zero
	if($.cookie("sifter") > 0)
	{
		self.playerId = $.cookie("sifter");
	}

    this.addNoteFromData = function(note)
    { 
        //Fix up note tags
        //note.tags.sort(
          //  function(a, b) {
          //      if(a.tag.toLowerCase() < b.tag.toLowerCase()) return -1;
          //      if(a.tag.toLowerCase() > b.tag.toLowerCase()) return 1;
          //      return 0;
          //  });
        // if(note.tags.length == 0) note.tags[0] = {"tag":'(untagged)'}; //conform to tag object structure
        note.tagString = note.tags[0].tag;  //all notes are required to have one, and only one, tag
        //for(var k = 0; k < note.tags.length; k++)
        //    note.tagString += note.tags[k].tag+', ';
        //note.tagString = note.tagString.slice(0,-2); 
        note.geoloc = new google.maps.LatLng(note.lat, note.lon);
        this.gameNotes[this.gameNotes.length] = note;
    }

    this.populateFromData = function(rawNotes)
    {	//the notes coming in need some processing
		this.rawNotes = rawNotes;
        for(var i = 0; i < this.rawNotes.length; i++)
        {
                this.addNoteFromData(this.rawNotes[i]);
        }
    };

    this.views = new function Views()
    { 
        //Content
        this.mainView 					= document.getElementById('main_view_full');
        //this.mainView.addEventListener('click', function(e) { e.stopPropagation(); });
        this.mainViewLeft              = document.getElementById('main_view_left');
		this.mainViewRight			   = document.getElementById('main_view_right');
        this.createNoteViewContainer   = document.getElementById('create_note_view_container');
        this.noteViewContainer         = document.getElementById('note_view_container');
        this.noteViewCloseButton       = new ActionButton(document.getElementById('note_view_close_button'), controller.hideNoteView);
        this.createNoteViewCloseButton = new ActionButton(document.getElementById('create_note_view_close_button'), controller.hideCreateNoteView);
        this.loginViewCloseButton      = new ActionButton(document.getElementById('login_view_close_button'), controller.hideLoginView);
        this.joinViewCloseButton       = new ActionButton(document.getElementById('join_view_close_button'), controller.hideJoinView);
        this.loginViewContainer        = document.getElementById('login_view_container');
        this.joinViewContainer         = document.getElementById('join_view_container');
        this.constructNoteView         = document.getElementById('note_view_construct');
        this.constructNoteCreateView   = document.getElementById('note_create_view_construct');
        this.constructLoginView     	= document.getElementById('login_view_construct');
        this.constructJoinView      	= document.getElementById('join_view_construct');
		this.uploadButton 				= document.getElementById('uploadButton'); //CDH
		this.loginButton				= document.getElementById('loginButton'); //CDH
		this.logoutButton				= document.getElementById('logoutButton');

		if(self.playerId > 0){ //if the cookie indicated they are logged in
			this.loginButton.style.display = 'none'; // hide login
			this.logoutButton.style.display = 'inline'; //They are logged in, let them log out
    		this.uploadButton.style.display = 'inline'; // show upload		
		}
		else{
			this.uploadButton.style.display = 'none'; // hide until login
			this.logoutButton.style.display = 'none';
		}

        this.likeIcon     = '<img id="likeIcon" src="./assets/images/LikeIcon.png" height=10px; />';
        this.commentIcon  = '<img src="./assets/images/CommentIcon.png" height=8px; />';
        this.noteIcon     = '';

		this.darkness		    = document.getElementById("darkBackgroundLayer");
		this.darkness.style.display = 'none'; 

        //Map
        this.map = document.getElementById('main_view_map');
        var centerLoc = new google.maps.LatLng(0, 0);
        var myOptions = { zoom:5, center:centerLoc, mapTypeId:google.maps.MapTypeId.ROADMAP };
        this.gmap = new google.maps.Map(this.map, myOptions);
		
		//default map pin location is in lake, where no notes are expected. User must move this pin to submit a note.
		this.defaultLat = 43.081829;
		this.defaultLon = -89.402313;
 
        // marker clusterer
        var mcOptions = { styles: [
            { height:53, url:"./assets/images/speechBubble_cluster_large.png", width:41, anchor:[15,17], fontFamily:"Helvetica, Arial" },
            { height:53, url:"./assets/images/speechBubble_cluster_large.png", width:41, anchor:[15,13], fontFamily:"Helvetica, Arial" },
            { height:53, url:"./assets/images/speechBubble_cluster_large.png", width:41, anchor:[15,13], fontFamily:"Helvetica, Arial" },
            { height:53, url:"./assets/images/speechBubble_cluster_large.png", width:41, anchor:[15,13], fontFamily:"Helvetica, Arial" },
            { height:53, url:"./assets/images/speechBubble_cluster_large.png", width:41, anchor:[15,13], fontFamily:"Helvetica, Arial" }
        ]};
        
        this.markerclusterer = new MarkerClusterer(this.gmap,[],mcOptions);
        
        this.markerclusterer.setMinimumClusterSize(3)
    };
}
