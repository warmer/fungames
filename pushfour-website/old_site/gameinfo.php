<?php

include_once('functions.php');
include_once('game.php');
include_once('board.php');

$openchar = "+";
$gameIDs = null;

/*
echo "game:".$_GET['gameid'];
echo "empty:-".!empty($_GET['gameid'])."-";
echo "isnumeric:-".is_numeric($_GET['gameid'])."-";

echo "player:".$_GET['playerid'];
echo "empty:-".!empty($_GET['playerid'])."-";
echo "isnumeric:-".is_numeric($_GET['playerid'])."-";
*/

function displayArray1D($players)
{
	$str = "";
	foreach($players as $id => $color)
	{
		$str .= $color;
	}
	echo $str;
}

if( !empty($_GET['gameid']) && is_numeric($_GET['gameid']) && !empty($_GET['playerid']) && is_numeric($_GET['playerid']) )
{

	$game = new Game( $_GET['gameid'] );
	//var_dump($game);
	$query = "	SELECT colorShortcut
			FROM tblcolors
			WHERE colorID IN (  SELECT colorID
					    FROM tblgameplayers
					    WHERE gameid=".intval($_GET['gameid'])." AND playerid=".intval($_GET['playerid'])." ) ";

    $mysqli = mysqli_db_connect();
    if( $mysqli )
    {
        $result = mysqli_query($mysqli, $query );
        if( $result )
        {
            if( $row = mysqli_fetch_assoc( $result ) )
            {
                $playercolor = $row['colorShortcut'];
            }//end while
        }
    }
	$players = null;
	foreach($game->players as $row)
    {
		$players[] = $row['colorShortcut'];
    }

	$bs = $game->board->board_str;
	$bs = str_replace(" ",$openchar,$bs);

	//protocol:
	//open char, board string, height, width, num players, player colors, player color, difficulty
	echo $openchar.",";
	echo $bs,",";
	echo $game->board->ySize.",";
	echo $game->board->xSize.",";
	echo sizeof($game->players).",";
	displayArray1D($players);
	echo ",";
	echo $playercolor;


}//end if
else
{
	echo 0;
}//end else

















?>
