<?php

include_once('functions.php');

$gameIDs = null;

if( !empty( $_GET['playerid'] ) && is_numeric( $_GET['playerid'] ) )
{
	$mysqli = mysqli_db_connect();
	//
	/*$query = "	SELECT gameID,gameStatus
			FROM tblgames 
			WHERE gameStatus < 2 AND gameID IN
			(	SELECT gameID 
				FROM tblGamePlayers 
				WHERE playerID=".$_GET['playerid']."   ) ";
	//*/
	$query = "	SELECT * 
			FROM tblgames AS tg
			INNER JOIN tblgameplayers tgp ON tg.gameID=tgp.gameID 
			WHERE tg.currentTurn=tgp.orderNumber 
			AND tgp.playerid=".$_GET['playerid']." AND tg.gameStatus<2 ";
	//echo $query;	
    $result = mysqli_query($mysqli, $query );
	$gameIDs = null;
	if( $result )
	{			
		while( $row = mysqli_fetch_assoc( $result ) )
		{	
			$gameIDs[] = $row['gameID'];
		}//end if				
	}//end if
	else
	{
        $errors .= "Couldn't get player information: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
	}//end else		

}//end if
else
{
	echo 0;
}//end else



if(sizeof($gameIDs) > 0)
{
	$disp = "";
	foreach($gameIDs as $gameID)
		$disp .= $gameID.",";
	
	$disp = substr($disp,0,strlen($disp)-1);
	echo $disp;
}//end if
else
	echo 0;

?>
