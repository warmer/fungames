<script language="javascript" type="text/javascript">
var clicked = 0;
var updateTimer = null;
var turn = 0;
function returnObjByID( id )
{
    if (document.getElementById)
        var returnVar = document.getElementById(id);
    else if (document.all)
        var returnVar = document.all[id];
    else if (document.layers)
        var returnVar = document.layers[id];
    return returnVar;
}

/**
 * @name fb()
 * @param scol start column
 * @param ecol start column
 * @param srow start row
 * @param erow start row
**/
function fb( scol, ecol, srow, erow, color)
{
	if( clicked == 1 )
	{
		return;
	}
	for( var x = srow; x <= erow; x++ )
	{
		for( var y = scol; y <= ecol; y++ )
		{
			if( td = returnObjByID( y + "-" + x ) )
			{
				td.bgColor = color;
			}
			else
			{
				break;
			}
		} // END column filling
	} // END row filling
} // END fill_blocks function

/**
 * @name glow
 * @param item the TD element to change
 * @param color the color to change the TD element
**/
function glow( item, color )
{
	var td = returnObjByID( item );
	if( clicked == 1 )
	{
		return;
	}
	td.bgColor = color;
}

function pollGameUpdate()
{
	var xmlHttp = GetXmlHttpObject();
	var url = "status_check.php?game={GAMEID}&t=" +  + (new Date()).getTime();
	if(xmlHttp == null)
	{
		return false;
	}
	// assign a function to the event indicator
	xmlHttp.onreadystatechange = function()
	{
		// response is ready and sent by the server
		if( xmlHttp.readyState == 4 )
		{
//			alert( xmlHttp.responseText + " turn: " + turn + " turn==resp?: " + (parseInt(xmlHttp.responseText) == turn) );
			if( parseInt(xmlHttp.responseText) != turn )
			{
				turn = parseInt(xmlHttp.responseText);
				get_board('{URL_OPTIONS}');
			}
		}
	}
	// open the data stream
	xmlHttp.open( "GET", url, true );
	xmlHttp.send( null );
	updateTimer = setTimeout("pollGameUpdate()",3000);
}

// AJAX functionality
function GetXmlHttpObject()
{
	var xmlHttp = null;
	try
	{
		// Firefox, Opera 8.0+, Safari
		xmlHttp = new XMLHttpRequest();
	}
	catch (e)
	{
		// Internet Explorer
		try
		{
			xmlHttp = new ActiveXObject("Msxml2.XMLHTTP");
		}
		catch (e)
		{
			xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
		}
	}
	return xmlHttp;
}

/** 
 * @name get_board
 * @param params the GET variables that will be passed to the manager
**/
function get_board(params)
{
	var xmlHttp = GetXmlHttpObject();
	var url = "manager.php?"+params+"&t=" + (new Date()).getTime();
	clicked = 1;
	if(xmlHttp == null)
	{
		return false;
	}
	// assign a function to the event indicator
	xmlHttp.onreadystatechange = function()
	{
		// response is ready and sent by the server
		if( xmlHttp.readyState == 4 )
		{
			document.getElementById("game_board").innerHTML = xmlHttp.responseText;
			clicked = 0;
		}
	}
	//cClick();
	//document.getElementById("game_board").innerHTML = "Updating...";
	// open the data stream
	xmlHttp.open( "GET", url, true );
	xmlHttp.send( null );
}
// initialization
function init()
{
	get_board('{URL_OPTIONS}');
	updateTimer = setTimeout("pollGameUpdate()",3000);
}

</script>
<div id="game_board" class="main_area">
	<h1>{BODY_TEXT}</h2>
</div>
