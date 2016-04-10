<?php
/**
 * register.php
 *
 * Handles user registration
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
	"register"	=> "register.tpl",)
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
	"TITLE"				=> "PushFour - Registration",
	"WELCOME_MESSAGE"	=> "Welcome to Eric's PushFour.  Please register!",
	)
);

/**
 * POST HANDLING HERE
**/
$allowed_username_chars = "a-zA-Z0-9_ -";
$allowed_email_chars = "\@\.a-zA-Z0-9_ \-";

if( !empty($_POST) )
{
	// first, destroy any session variables if someone is attempting to log in
	// again, just in case
	$_SESSION = array();
	session_destroy();
	
	$username = @$_POST['username'];
	$pw1 = @$_POST['password'];
	$pw2 = @$_POST['password2'];
	$email = @$_POST['email'];
	
	
	
	$sanitized_username = sanitize( $username, $allowed_username_chars );
	$sanitized_pw = addslashes( $pw1 );
	$sanitized_email = sanitize( $email, $allowed_email_chars );
	$sanitized_email = filter_var( $sanitized_email, FILTER_VALIDATE_EMAIL );
	
	/* username problems */
	// username is too long or too short
	if( empty( $sanitized_username ) || (strlen( $sanitized_username ) > 32) )
	{
		$errors .= "Your username must be between 1 and 32 characters long.<br />\r";
	}
	// username had invalid characters - instead of passing, let the user know
	// (they might want to revise their name)
	// this compares pre-sanitized to sanitized usernames
	else if( $username != $sanitized_username )
	{
		$errors .= "Your username contains invalid characters.  Only alpha-numeric characters, -, and _ are allowed.<br />\r";
	}
	/* password problems */
	// passwords don't match
	if( $pw1 != $pw2 )
	{
		$errors .= "The passwords must match.<br />\r";
	}
	// password too long or too short
	else if( (strlen( $sanitized_pw ) < 4) || (strlen( $sanitized_pw ) > 32) )
	{
		$errors .= "Your password must be between 4 and 32 characters long.<br />\r";
	}
	// sanitization changed the password somehow
	else if( $sanitized_pw != $pw1  )
	{
		$errors .= "Your password contained invalid characters.  Please revise it.<br />\r";
	}
	/* email problems */
	// note, email is optional
	if( strlen( $email ) > 0 )
	{
		// didn't pass PHP's email test
		if( $sanitized_email === false )
		{
			$errors .= "The email address you provided is invalid.  Please revise it.<br />\r";
		}
		// cap email length at 64 characters
		else if( strlen( $sanitized_email ) > 64 )
		{
			$errors .= "Email addresses longer than 64 characters, while technically legal, are not permitted here.<br />\r";
		}
	}
	
	$md5_pw = md5( $sanitized_pw );
	$now = mktime();
	
	// if there were no errors...
	if( strlen($errors) == 0 )
	{
		$query = "INSERT INTO tblPlayers
			(name, password, joined, email)
			VALUES
			('$sanitized_username', '$md5_pw', '$now', '$sanitized_email')";
		$errors .= "$query<br />\r";
		
	}
	
	
	
	$mysqli = mysqli_db_connect();
    if( !$mysqli )
    {
        $errors .= "Couldn't connect to the database: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
    }
    else
    {
        $result = mysqli_query($mysqli, $query );
        if( !$result )
        {
            if( mysqli_connect_errno($mysqli) == "1062" )
            {
                $errors .= "There is already a user with the user name
                            '$sanitized_username.'  First come, first serve
                            - sorry!<br /><br />\r";
            }
            else
            {
                $errors .= "MySQL Error ".@mysqli_connect_errno($mysqli).": ".@mysqli_connect_error()."</b><br />\r";
            }
        }
        else
        {
            $_SESSION["logged_in"] = TRUE;
            
            $_SESSION["name"] = $sanitized_username;
            $_SESSION["playerID"] = mysqli_insert_id($mysqli);
            $_SESSION["joined"] = $now;
            $_SESSION["user_email"] = $sanitized_email;
            
            session_write_close();
            header( "Location:index.php?src=reg&" );
            exit();
        }
    }
}
/**
 * END POST HANDLING
**/


/**
 * Forward to index if the user is logged in already.
**/
if( @$_SESSION["logged_in"] )
{
	session_write_close();
	header( "Location:index.php" );
	exit();
}


if( !empty( $errors ) )
{
	$template->assign_block_vars( "error", array(
			"ERROR"			=> $errors,
		)
	);
}


$template->pparse( "header" );		// set in header.php
$template->pparse( "register" );
$template->pparse( "footer" );		// set in footer.php


?>
