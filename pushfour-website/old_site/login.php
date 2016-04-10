<?php
/**
 * login.php
 *
 * Handles logging in and logging out
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

$template->set_filenames( array(
	"login"	=> "login.tpl",)
);

$errors = "";

// Don't bother loading the rest of the page if the user is already logged in
// They shouldn't be here
if( @$_SESSION["logged_in"] )
{
	session_write_close();
	header( "Location:index.php" );
	exit();
}

$template->assign_vars( array(
	"TITLE"				=> "PushFour - Login",
	"WELCOME_MESSAGE"	=> "Welcome to Eric's PushFour.  Please log in!",
	)
);


/**
 * POST HANDLING HERE
**/
$allowed_username_chars = "a-zA-Z0-9_ -";

if( !empty($_POST) )
{
	// first, destroy any session variables if someone is attempting to log in
	// again, just in case
	$session_name = session_name();
	$_SESSION = array();
	
	$username = @$_POST['username'];
	$pw = @$_POST['password'];
	
	$sanitized_username = sanitize( $username, $allowed_username_chars );
	$sanitized_pw = addslashes( $pw );
	
	$password = md5( $sanitized_pw );
	
	$query = "SELECT * FROM tblPlayers WHERE name='$sanitized_username'";
	
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
            if( @mysqli_num_rows( $result ) == 0 )
            {
                $errors .= "User could not be authenticated. <br /><br />\r";
            }
            else
            {
                $result = @mysqli_fetch_assoc( $result );
                if( $result['password'] != $password )
                {
                    $errors .= "User could not be authenticated. <br /><br />\r";
                }
                else
                {
                    $_SESSION['logged_in'] = TRUE;
                    
                    $_SESSION["name"] = @$result['name'];
                    $_SESSION["playerID"] = @$result['playerID'];
                    $_SESSION["joined"] = @$result['joined'];
                    $_SESSION["user_email"] = @$result['email'];
                    $_SESSION["token"] = md5($password . mktime() );
                    
                    session_write_close();
                    header( "Location:index.php" );
                    exit();
                }
            }
        }
        else
        {
            $errors .= "Couldn't authenticate user: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
        }
    }
}
/**
 * END POST HANDLING
**/

// display errors, if any
if( !empty( $errors ) )
{
	$template->assign_block_vars( "error", array(
			"ERROR"			=> $errors,
		)
	);
} // END error display

$template->pparse( "header" );		// set in header.php
$template->pparse( "login" );
$template->pparse( "footer" );		// set in footer.php


?>
