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
	"main"	=> "instant_match.tpl",)
);

$url_options = "";

if( empty( $_GET['game'] ) && empty( $_POST['game'] ) )
{		
	$url_options .= "game=new&";
	//X size
	if( !empty($_POST['xsize']) && is_numeric($_POST['xsize']) )
		$url_options .="x=".$_POST['xsize'];
	else
		$url_options .="x=10";
	//Y size
	if( !empty($_POST['ysize']) && is_numeric($_POST['ysize']) )
		$url_options .="&y=".$_POST['ysize'];
	else
		$url_options .="&y=10";			
	//Number of obstacles
	if( !empty($_POST['numObs']) && is_numeric($_POST['numObs']) )
		$url_options .="&obs=".$_POST['numObs'];
	else
		$url_options .="&obs=10";
	//Board ID
	if( !empty($_POST['boardID']) && is_numeric($_POST['boardID']) )
		$url_options .="&board=".$_POST['boardID'];
	else
		$url_options .="&board=0";	
	//1st player ID
	if(!empty($_POST['playerID1']) && is_numeric(strrev(  substr(   strrev($_POST['playerID1']), 0, strpos(strrev($_POST['playerID1']),"-")))))
	{
		$playerID1 = strrev(  substr(   strrev($_POST['playerID1']), 0, strpos(strrev($_POST['playerID1']),"-")));	
		$url_options .="&playerID1=".$playerID1;
	}//end if
	else
	{
		$url_options .="&playerID1=1";	//playerID = 1 is Default Player 1
	}//end else	

	//2nd player ID
	if(!empty($_POST['playerID2']) && is_numeric(strrev(  substr(   strrev($_POST['playerID2']), 0, strpos(strrev($_POST['playerID2']),"-")))))
	{
		$playerID2 = strrev(  substr(   strrev($_POST['playerID2']), 0, strpos(strrev($_POST['playerID2']),"-")));	
		$url_options .="&playerID2=".$playerID2;
	}//end if
	else
	{
		$url_options .="&playerID2=2";  //playerID = 2 is Default Player 2
	}//end else	
}//end if
else
{
	if( !empty($_GET['game']) )
		$game = intval( $_GET['game'] );
	else
		$game = intval( $_POST['game'] );
	
	$player = intval( @$_GET['player'] );
	$url_options .= "game=$game&player=$player";
}//end else


$template->assign_vars( array(
		"URL_OPTIONS"			=> $url_options,
		"TURN"					=> 0,
		"GAMEID"				=> $game,
		"BODY_LOAD_FUNCTION"	=> "init()",
	)
);

$template->pparse( "header" );		// set in header.php
$template->pparse( "main" );
$template->pparse( "footer" );		// set in footer.php


?>
