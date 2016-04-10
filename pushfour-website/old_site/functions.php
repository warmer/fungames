<?php
/**
 * functions.php
 *
 * Handles session initialization and destruction and contains functions common
 * to most or all pages
 *
 * Notes:
 *  status_check
 *  game
 *  board
 *  makegame
 *  manager
**/

/* ***SESSION MANAGEMENT*** */
// must call to enable session variables
session_start();
// handle 
if( (@$_GET['do'] == "logout") )
{
	$_SESSION = array();
	if( isset( $_COOKIE[session_name()] ) )
	{
		setcookie(session_name(), '', time()-42000, '/');
	} // clear the cookie
	
	session_destroy();
	$_SESSION["logged_in"] = FALSE;
}

/**
 * Connects to the pushfour database and returns the connection id
 * 
 * @access		private
**/
function db_connect()
{
	$host = 'pushfour.net';
    $usr = 'pushfour_poshfer';
    $pwd = 'BWXa^J~E(b[T';
	$database = 'pushfour_pushfour';
	
	/*$host = 'localhost';
	$usr = 'root';
	$pwd = 'whit';
	$database = 'pushfour';
	*/
    return mysqli_connect($host, $usr, $pwd, $database);
	//mysql_connect( $host, $usr, $pwd );
	//mysql_select_db( $database );
}//end function db_connect

function mysqli_db_connect()
{
	$host = 'pushfour.net';
    $usr = 'pushfour_poshfer';
    $pwd = 'BWXa^J~E(b[T';
	$database = 'pushfour_pushfour';
	
    return mysqli_connect($host, $usr, $pwd, $database);
}

/**
 * Sanitizes the input given a list of allowed characters.  This is better
 * than removing bad characters because it is more complete.
 *
 * @example sanitize( $_POST['username'], "a-zA-Z0-9_\- ");
 *			allows character ranges and "_", "-", and " " (space)
 * 
 * @param input the string to be sanitized
 * @param allowed the regex-compatible string of valid characters
 * @return string containing only characters in the allowed string
**/
function sanitize( $input, $allowed)
{
	$output = preg_replace("/[^$allowed]/", "", $input);
	return $output;
}

?>