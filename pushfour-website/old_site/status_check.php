<?php
include('board.php');
include('game.php');
include_once('functions.php');
	

set_time_limit(0);



//MAIN PROGRAM******************************************************************

error_reporting(0);

if( !empty( $_GET['game'] ) && is_numeric( $_GET['game'] ) )
{

	$game = new Game( $_GET['game'] );
	//echo "<pre>Board string:--".$game->board->board_str."--</pre>";
	
	if( $game->gameStatus < 2 )
	{
		echo $game->moveNumber;
	}//end if
	else
	{
		echo -1;
	}//end else
	
}
else
{
	echo 0;
}
?>
