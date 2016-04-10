<?php
/**
 * about.php
 *
 * About the game
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
	"about"		=> "about.tpl",)
);




/***********************/
/* PAGE BODY GOES HERE */
/***********************/




$template->pparse( "header" );		// set in header.php
$template->pparse( "about" );
$template->pparse( "footer" );		// set in footer.php


?>
