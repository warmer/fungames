<?php
/**
 * makegame.php
 *
 * Allows a user to select all of the parameters for a game:
 *	-height
 *	-width
 *	-number of players (TBC)
 *	-opponent(s) (TBC)
 *	-colors (TBC)
 *	-number of barricades
 *	-existing board template (TBC, optional)
 *
 * When called without GET parameters, the fields are set to defaults:
 *	-height: 10
 *	-width: 10
 *	-number of players: 10
 *	-opponent: Guest Player
 *	-colors: red (1), blue (2)
 *	-number of barricades: 10
 *	-existing board template: no
**/
// this inserted so that header and footer cannot be called separately
define('IN_PUSHFOUR', true);

include("functions.php");

include('board.php');
include('game.php');

include("template.php");
$template = new Template();

// handle common header and footer functionality, including look-and-feel
// header.php ends AFTER opening the <BODY> tag
include("header.php");
// footer.php begins BEFORE the </BODY> tag
include("footer.php");

// change this to mate the purpose of the current page
$template->set_filenames( array(
	"makegame"	=> "makegame.tpl",)
);

$errors = "";


//INITIALIZE********************************************************************
//Initialize
// array containing possible player ID entries
$registered_players = getPlayerInfo();
$selected_players = array();
$width = 10;
$height = 10;
$num_obs = 8;
$num_players = 2;
//END INITIALIZE****************************************************************



//FUNCTIONS*********************************************************************
/**
 * Gets the player information
 *
 * @access		private
 * @return	array of players in the database
**/
function getPlayerInfo()
{
	$ret = 0;
	global $errors;
	$query = "SELECT name,playerID
		  FROM tblplayers ; ";
	$registered_players = array();
	$mysqli = mysqli_db_connect();
    if( !$mysqli )
    {
        $errors .= "Couldn't connect to the database: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
    }
    else
    {
        $result = mysqli_query($mysqli, $query );
        if( $result )
        {
            global $names, $playerIDs;
            while( $row = mysqli_fetch_assoc( $result ) )
            {
                //If players were found, update the player info array
                $registered_players[$row['playerID']] = $row['name'];
            }
        }
        else
        {
            $errors .= "Couldn't get player information: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
        }
    }
	return $registered_players;
}//end function getPlayerInfo
//END FUNCTIONS*****************************************************************

$form = array();

if(!empty($_GET))
{
    $form = $_GET;
}
else if(!empty($_POST))
{
    $form = $_POST;
}

//POST HANDLING*****************************************************************
if( !empty($form) )
{
	$height = @$form['ysize'];
	$width = @$form['xsize'];
	$num_obs = @$form['numObs'];

	$sanitized_height = intval( sanitize( $height, "0-9" ) );
	$sanitized_width = intval( sanitize( $width, "0-9" ) );
	$sanitized_num_obs = intval( sanitize( $num_obs, "0-9" ) );

	// tests for invalid characters included in the POST string
	if( $height != $sanitized_height )
	{
		$errors .= "Invalid board height.<br /><br />\r";
	}
	if( $width != $sanitized_width )
	{
		$errors .= "Invalid board width.<br /><br />\r";
	}
	if( $num_obs != $sanitized_num_obs )
	{
		$errors .= "Invalid number of obstacles.<br /><br />\r";
	}

	$selected_players = array();
	$playerIds = array();
	// check each posted player;
	// NOTE: will need to fix this if/when there can be more than 2 players
	for( $i = 1; $i <= $num_players; $i++)
	{
		$id = @$form["player_$i"];
		$sanitized_id = intval( sanitize( $id, "0-9" ) );

		// test for invalid characters
		if( $id != $sanitized_id )
		{
			$errors .= "Invalid ID for player $i<br /><br />\r";
		}
		else if( array_key_exists( $sanitized_id, $selected_players ) )
		{
			$errors .= "Player $i and player ".$selected_players[$sanitized_id]["player_num"]." cannot be the same.<br /><br />\r";
		}
		else if( isset( $registered_players[$sanitized_id] ) )
		{
			$selected_players[$sanitized_id] = $registered_players[$sanitized_id];
			$selected_players[$sanitized_id]["player_num"] = $i;
			$playerIDs[] = $sanitized_id;
		}
		else
		{
			$errors .= "Cannot find player $i.<br /><br />\r";
		}
	} // END for loop - for the number of players

	// there are no errors, so go ahead and create a board
	if( empty( $errors ) )
	{
		$aGame = new Game();
		$newboard = new Board($width, $height, $num_obs);
		$boardNum = $newboard->boardID;
		$aGame->new_game($boardNum, $width, $height, $num_obs, $playerIDs[0], $playerIDs[1]);
		header("Location:index.php?game=" . $aGame->gameID );
	}

	var_dump($_POST);

	header( "Location:index.php" );
//	exit();
}
//END POST HANDLING*************************************************************




//MAIN PROGRAM******************************************************************

//Setup form
for($i = 1; $i < ($num_players + 1); $i++)
{
	$template->assign_block_vars( "player_selection", array(
			"PLAYER_NUM"	=> $i,
		)
	);

	//Display names
	foreach( $registered_players as $player_ID => $player_name )
	{
		$selected = "";
		if( $player_ID == @$_SESSION["playerID"] )
		{
			$selected = "SELECTED";
		}
		$template->assign_block_vars( "player_selection.option", array(
				"TEXT"		=> $player_name,
				"VALUE"		=> $player_ID,
				"SELECTED"	=> $selected,
			)
		);
	}//end for loop - loading of players in the database
}//end for loop - one for each opponent in this game
//END MAIN PROGRAM**************************************************************


// display errors, if any
if( !empty( $errors ) )
{
	$template->assign_block_vars( "error", array(
			"ERROR"			=> $errors,
		)
	);
} // END error display

$template->pparse( "header" );		// set in header.php
$template->pparse( "makegame" );
$template->pparse( "footer" );		// set in footer.php


?>
