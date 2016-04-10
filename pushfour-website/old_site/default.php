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
	"default"	=> "default.tpl",)
);

$errors = "";




/***********************/
/* PAGE BODY GOES HERE */
/***********************/




$template->pparse( "header" );		// set in header.php
$template->pparse( "default" );
$template->pparse( "footer" );		// set in footer.php


?>
