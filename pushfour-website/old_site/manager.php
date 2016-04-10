<?php
include('template.php');
include('board.php');
include('game.php');
include_once('functions.php');

$errors = "";

$template = new Template();
$template->set_filenames( array(
	"board"	=> "board.tpl",)
);


$game;
$boardID = 0;

/*
GET PARAMETERS OBTAINED HERE
*/
if( !empty( $_GET['board'] ) && is_numeric( $_GET['board'] ) )
{
	$boardID = intval($_GET['board']);	
}

if( !empty( $_GET['game'] ) && is_numeric( $_GET['game'] ) )
{
	$game = new Game( $_GET['game'] );
}
else
{	// NOTE: the "true" statement here DEFAULTS a blank game to a new game!
	if( $_GET['game'] == "new" || true )
	{
		$game = new Game();
		$game->new_game( $boardID, @$_GET['x'], @$_GET['y'], @$_GET['obs'], @$_GET['playerID1'], @$_GET['playerID2'] );				
	}
}// END looking at 'game' GET parameter
// player ID
if( !empty( $_GET['player'] ) && is_numeric( $_GET['player'] ) )
{
	$player = intval( $_GET['player'] );
}//end if
else
{
	$player = 0;
}//end else

// move side
$sides = $game->board->side_codes;
if( !empty( $_GET['side'] ) && in_array($_GET['side'], $sides) )
{
	$side = substr( $_GET['side'], 0, 1);
}
// row or column
if( isset( $_GET['channel'] ) && is_numeric( $_GET['channel'] ) )
{
	$channel = intval( $_GET['channel'] );
}

//someone made a move!
if( isset($channel) && isset($side) )
{	
	$moveCoords = $game->translate_move( $side, $channel);
	$game->make_move($moveCoords["x"],$moveCoords["y"],$player);
}//end if


$game->print_board($template, $player, $game->gameID);

$errors .= $game->get_errors();
$game_info = $game->get_info();

if( !empty($game_info) )
{
	$template->assign_block_vars( "message", array(
			"CLASS"		=> "info",
			"MESSAGE"	=> $game_info,
		)
	);
}
if( !empty($errors) )
{
	$template->assign_block_vars( "message", array(
			"CLASS"		=> "errors",
			"MESSAGE"	=> $errors,
		)
	);
}

// add all the header information...
if( @$_GET['test'] == "true" )
{
	$template->assign_block_vars( "head", array() );
	
	$template->assign_block_vars( "foot", array() );
}

$template->pparse( "board" );

?>
