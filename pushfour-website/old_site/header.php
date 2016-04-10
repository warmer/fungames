<?php
/**
 * header.php
 *
 * Sets a default title and displays all page header information that
 * is common for all of the viewable pushfour pages
**/
// header was called out of context
if( !defined('IN_PUSHFOUR') )
{
	die("");
}

$template->set_filenames( array(
	"header"	=> "header.tpl",)
);

$template->assign_vars( array(
	"TITLE"				=> ":: Pushfour ::",
	)
);

$username = "Guest";
$login_URL = "./login.php?";
$login_TEXT = "Log in";
// 
if( @$_SESSION["logged_in"] == TRUE )
{
	$username = @$_SESSION["name"];
	$login_URL = "./login.php?do=logout";
	$login_TEXT = "Log out";
	
	$template->assign_block_vars( "title_link", array(
		"URL"				=> $login_URL,
		"TEXT"				=> $login_TEXT,
		)
	);
	$template->assign_vars( array(
		"MESSAGE"			=> "Welcome, $_SESSION[name]!",
		)
	);
}
else
{
	$template->assign_block_vars( "title_link", array(
		"URL"				=> $login_URL,
		"TEXT"				=> $login_TEXT,
		)
	);
	
	$template->assign_block_vars( "title_link.spacer_right", array() );
	
	$template->assign_block_vars( "title_link", array(
		"URL"				=> "./register.php?",
		"TEXT"				=> "Register",
		)
	);
}


?>
