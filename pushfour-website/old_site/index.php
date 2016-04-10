<?php
/**
 * default.php
 *
 * Description of what this page does
 * Use as template for all pages created FOR VIEWING by pushfour project
**/
// this inserted so that header and footer cannot be called separately
define('IN_PUSHFOUR', true);

include("functions.php");

include("template.php");
$template = new Template();

// handle common header and footer functionality, including look-and-feel
// header.php ends AFTER opening the <BODY> tag
include("header.php");
// footer.php begins BEFORE the </BODY> tag
include("footer.php");

// change this to mate the purpose of the current page
$template->set_filenames( array(
	"main"	=> "main.tpl",)
);

$url_options = "";

/* ***************************************************************** */
/* SECURITY ISSUES IN THIS CODE: POST DATA DIRECTLY USED FOR JS VARS */
/* additionally, 3.4 is numeric, but not valid....					 */
/* ***************************************************************** */
if( empty( $_GET['game'] ) && empty( $_POST['game'] ) )
{
	// Create a new board...
	$xSize = filter_input(INPUT_POST, "xsize", FILTER_SANITIZE_NUMBER_INT, array("options"=>
array("min_range"=>4, "max_range"=>15)));
	$ySize = filter_input(INPUT_POST, "ysize", FILTER_SANITIZE_NUMBER_INT, array("options"=>
array("min_range"=>4, "max_range"=>15)));
	$numObs = filter_input(INPUT_POST, "numObs", FILTER_SANITIZE_NUMBER_INT, array("options"=>
array("min_range"=>0, "max_range"=>20)));
	$boardId = filter_input(INPUT_POST, "boardId", FILTER_SANITIZE_NUMBER_INT);
	$player1 = filter_input(INPUT_POST, "playerID1", FILTER_SANITIZE_NUMBER_INT);
	$player2 = filter_input(INPUT_POST, "playerID2", FILTER_SANITIZE_NUMBER_INT);


	$url_options .= "game=new";
	//X size
	if( !empty($xSize) )
	{
		$url_options .="&x=".$xSize;
	}
	else
	{
		$url_options .="&x=10";
	}
	//Y size
	if( !empty($ySize) )
	{
		$url_options .="&y=".$ySize;
	}
	else
	{
		$url_options .="&y=10";
	}
	//Number of obstacles
	if( !empty($numObs) )
	{
		$url_options .="&obs=".$numObs;
	}
	else
	{
		$url_options .="&obs=10";
	}
	//Board ID
	if( !empty($boardId) )
	{
		$url_options .="&board=".$boardId;
	}
	else
	{
		$url_options .="&board=0";
	}
	//1st player ID
	if(!empty($player1))
	{
		$url_options .="&playerID1=".$player1;
	}//end if
	else
	{
		$url_options .="&playerID1=1";	//playerID = 1 is Default Player 1
	}//end else

	//2nd player ID
	if(!empty($player2))
	{
		$url_options .="&playerID2=".$player2;
	}//end if
	else
	{
		$url_options .="&playerID2=1";	//playerID = 2 is Default Player 2
	}//end else
//	if(!empty($_POST['playerID2']) && is_numeric(strrev(  substr(   strrev($_POST['playerID2']), 0, strpos(strrev($_POST['playerID2']),"-")))))
//	{
//		$playerID2 = strrev(  substr(   strrev($_POST['playerID2']), 0, strpos(strrev($_POST['playerID2']),"-")));
//		$url_options .="&playerID2=".$playerID2;
//	}//end if
//	else
//	{
//		$url_options .="&playerID2=2";  //playerID = 2 is Default Player 2
//	}//end else
	$template->assign_vars( array(
			"BODY_TEXT"				=> "<a href=\"makegame.php?\">New Pushfour Game</a>",
		)
	);
}//end if
else
{
	$game = filter_input(INPUT_GET, "game", FILTER_SANITIZE_NUMBER_INT);
	$player = filter_input(INPUT_GET, "player", FILTER_SANITIZE_NUMBER_INT);

	if( empty($game) )
	{
		$game = filter_input(INPUT_POST, "game", FILTER_SANITIZE_NUMBER_INT);
	}

	$url_options .= "game=$game&player=$player";
	$template->assign_vars( array(
			"BODY_LOAD_FUNCTION"	=> "init()",
			"BODY_TEXT"				=> "The game is loading...",
		)
	);
}//end else


$template->assign_vars( array(
		"URL_OPTIONS"			=> $url_options,
		"TURN"					=> 0,
		"GAMEID"				=> $game,
	)
);

$template->pparse( "header" );		// set in header.php
$template->pparse( "main" );
$template->pparse( "footer" );		// set in footer.php


?>
