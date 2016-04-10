<?php

include_once('functions.php');

/**
 * Game class
 *
 * contains methods for loading and creating a game
**/

class Game
{
	var $classname = "Game";

	var $gameID = 0;
	var $boardID = 0;
	var $board;

	var $errors = "";
	var $info = "";

	var $gameStatus = 0;

	var $players = array();

	var $playerTurn;

	var $moveNumber = -1;
	/**
	 * @name Game
	 * @param gameID existing game ID
	 *
	**/
	function Game($gameID = 0)
	{	// sanitize that input!
		$gameID = intval( $gameID );
		if( $gameID )
		{
			$query = "
				SELECT
					*
				FROM
					tblgames g, tblcolors c, tblgameplayers p
				WHERE
						g.gameID='$gameID'
					AND
						g.gameID=p.gameID
					AND
						c.colorID=p.colorID
				ORDER BY
					orderNumber ASC";
            $mysqli = mysqli_db_connect();
            $gameFound = false;
			if( ($result = mysqli_query($mysqli, $query )) )
			{
				while( $row = mysqli_fetch_assoc( $result ) )
				{
					$this->players[$row['orderNumber']] = $row;
					$this->gameID = $row['gameID'];
					$this->load_board( $row['boardID'] );
					$this->gameStatus = $row['gameStatus'];
					$this->playerTurn = $row['currentTurn'];
                    $gameFound = true;
				}//end while
				$this->load_moves();
			}//end if
			if( !$result )
			{
				$this->errors .= "Could not query Games database: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
			}//end else if
			else if(!$gameFound)
			{
				$this->new_game();
			}//end else
		}
	}

	/**
	 * @name new_game
	 * @param boardID if non-zero, looks at a gameID from the database and
	 *	ignores the other parameters
	 * @param xSize
	 * @param ySize
	 * @param numObstacles
	 * @param playerIDs	the array of playerID numbers, defaulting to 1,2
	 *
	**/
	function new_game( $boardID = 0, $xSize = 10, $ySize = 10, $numObstacles = 10, $playerID1 = 1, $playerID2 = 2 )
	{
		$this->board = new Board();

		if( is_numeric($boardID) || ( is_numeric($xSize) && is_numeric($ySize) && is_numeric($numObstacles) ) )
		{
			if( empty( $boardID ) || !$this->board->load_board($boardID) )
			{
				$this->board->new_board( $xSize, $ySize, $numObstacles );
			}//end if

			$boardID=$this->board->boardID;

				$query = "INSERT INTO tblgames
					(gameID, boardID, gameStatus)
				VALUES
					($this->gameID, $boardID, 1);";
				$mysqli = mysqli_db_connect();
				$result = mysqli_query($mysqli, $query );
				if( $result && !$gameID )
				{
					$this->gameID = mysqli_insert_id($mysqli);
					if( empty( $this->gameID ) )
					{
						$this->errors .= "Unable to find the newly created game in the database.<br /><br />\r";
					}
					else
					{
						/* DEFAULT HACK - add two users
						$this->add_player( 1, 1 );
						$this->add_player( 2, 2 );
						*/
						if( is_numeric($playerID1) && is_numeric($playerID2) )
						{
							$this->add_player($playerID1, 1);
							$this->add_player($playerID2, 2);
						}//end if
						else
							$this->errors .= "Could not create game - invalid player IDs.<br /><br />\r";
					} // END test for successful insert
				}//end if
				else if( !$result )
				{
					$this->errors .= "Couldn't create this game: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
				} // END catch of failed MySQL query
		}//end if
		else
		{
			$this->errors .= "Couldn't create this game - invalid board specifications.<br /><br />\r";
		} // END else for no board created or selected

	} // END new_game()

	/**
	 * @name load_board
	 * @param boardID
	 *
	**/
	function load_board( $boardID )
	{
		if( empty( $this->board ) )
		{
			$this->board = new Board();
			$this->board->load_board( $boardID );
		}
	}



		/**
	 * @name check_for_win
	 * @param move_x the x-coordinate of the last move
	 * @param move_y the y-coordinate of the last move
	 * @return	0 if board not won
	 *			1 if won -
	 *			2 if won |
	 *			3 if won \
	 *			4 if won /
	 *
	 * Uses the board's obstacle array and side, channel parameters to
	 *    translate the side,channel coordinates into x,y coordinates.
	 *    (0,0) is the upper left square
	**/
	function check_for_win($move_x, $move_y)
	{
		$rows = $this->board->ySize;
		$cols = $this->board->xSize;
		// 1-d array containing the populated board string
		$str =& $this->board->board_str;
		// the offset into the 1-d board array
		$offset = $move_x + $move_y*$cols;
		// the color of the piece that at the move location
		$color = $str{$offset};
		/* HORIZONTAL CHECK */
		$in_line = 1;
		// check left
		$x = $move_x;
		while( (--$x) >= 0)
		{
			$offset--;
			if( $str{$offset} == $color )
			{
				$in_line++;
			}
			else
			{
				break;
			}//end else
		}
		// check right
		$x = $move_x;
		$offset = $move_x + $move_y*$cols;
		while( (++$x) < $cols )
		{
			$offset++;
			if( $str{$offset} == $color )
			{
				$in_line++;
			}
			else
			{
				break;
			}//end else
		}
		if( $in_line >= 4 )
		{
			return 1;
		}

		/* VERTICAL CHECK */
		$in_line = 1;
		// check up
		$y = $move_y;
		$offset = $move_x + $move_y*$cols;
		while( (--$y) >= 0)
		{
			$offset -= $cols;
			if( $str{$offset} == $color )
			{
				$in_line++;
			}
			else
			{
				break;
			}//end else
		}
		// check down
		$y = $move_y;
		$offset = $move_x + $move_y*$cols;
		while( (++$y) < $rows )
		{
			$offset += $cols;
			if( $str{$offset} == $color )
			{
				$in_line++;
			}
			else
			{
				break;
			}//end else
		}
		if( $in_line >= 4 )
		{
			return 2;
		}

		/* DIAGONAL LIKE \ CHECK */
		$in_line = 1;
		// check up and left
		$x = $move_x;
		$y = $move_y;
		$offset = $move_x + $move_y*$cols;
		while( ((--$y) >= 0) && ((--$x) >= 0) )
		{
			$offset -= $cols;
			$offset--;
			if( $str{$offset} == $color )
			{
				$in_line++;
			}
			else
			{
				break;
			}//end else
		}
		// check down and right
		$x = $move_x;
		$y = $move_y;
		$offset = $move_x + $move_y*$cols;
		while( ((++$y) < $rows) && ((++$x) < $cols) )
		{
			$offset += $cols;
			$offset++;
			if( $str{$offset} == $color )
			{
				$in_line++;
			}
			else
			{
				break;
			}//end else
		}
		if( $in_line >= 4 )
		{
			return 3;
		}


		/* DIAGONAL LIKE / CHECK */
		$in_line = 1;
		// check down and left
		$x = $move_x;
		$y = $move_y;
		$offset = $move_x + $move_y*$cols;
		while( ((++$y) < $rows) && ((--$x) >= 0) )
		{
			$offset += $cols;
			$offset--;
			if( $str{$offset} == $color )
			{
				$in_line++;
			}
			else
			{
				break;
			}//end else
		}
		// check up and right
		$x = $move_x;
		$y = $move_y;
		$offset = $move_x + $move_y*$cols;
		while( ((--$y) >= 0) && ((++$x) < $cols) )
		{
			$offset -= $cols;
			$offset++;
			if( $str{$offset} == $color )
			{
				$in_line++;
			}
			else
			{
				break;
			}//end else
		}
		if( $in_line >= 4 )
		{
			return 4;
		}


		return 0;
	}//END check_for_win function



	/**
	 * @name make_move
	 * @param x position of move
	 * @param y position of move
	 * @param playerID the player making the move
	 *
	**/
	function make_move($x, $y, $playerID)
	{
		//Get the order number for this player ID in this game
		$query = "SELECT orderNumber
			  FROM tblgameplayers
			  WHERE gameID= ".$this->gameID.
			  	" AND playerID=".$playerID."; ";
        $mysqli = mysqli_db_connect();
		$result = mysqli_query($mysqli, $query );
		if( $result )
		{
			if( $row = mysqli_fetch_assoc( $result ) )
			{
				$orderNumber = $row['orderNumber'];
			}//end if
			else
			{	// no game found
				$this->errors .= "Player order number could not be found.<br /><br />\r";
			}//end else
		}//end if
		else
		{
			$this->errors .= "Could get player order number information: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
		}//end else


		//Verify and insert the move
		if( $this->verify_move($x, $y, $playerID) )
		{
			//$colorID = $this->players[$playerID]['colorID'];
			//$orderNumber = $this->players[$playerID]['orderNumber'];
			$colorID = $this->players[$orderNumber]['colorID'];

			$query = "INSERT INTO tblmoves
					(gameID, colorID, orderNumber, moveX, moveY)
				VALUES
					($this->gameID, $colorID, $orderNumber, $x, $y );";
/*echo "PlayerID:".$playerID;
echo "Order Number:".$orderNumber;
echo $query;*/
			$result = mysqli_query($mysqli, $query );
			if( $result )
			{	// look for the last move that was made
				$query = "
					SELECT
						m.moveNumber, m.orderNumber, m.moveX, m.moveY, c.colorHex, c.colorShortcut
					FROM
						tblmoves m, tblcolors c
					WHERE
						m.gameID='$this->gameID' AND m.colorID=c.colorID
					ORDER BY
						m.moveNumber DESC
					LIMIT 1";
				$result = mysqli_query($mysqli, $query );
				if( !$result )
				{
					$this->errors .= "Could not find the last move: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
				}
				else
				{
					while( $row = mysqli_fetch_assoc( $result ) )
					{
						$this->board->add_move( $row );
					} // END while loop for getting moves
				} // END getting last move

				if( $how = $this->check_for_win($x, $y) )
				{
					$this->gameStatus = 2;
					$query = "UPDATE tblgames
						SET gameStatus=$this->gameStatus
						WHERE gameID=$this->gameID;";
					$mysqli = mysqli_db_connect();
					$this->errors .= "$how<br /><br />\r";
					$result = mysqli_query($mysqli, $query );
					if( !$result )
					{
						$this->errors .= "Could not send the end game mark: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
						return;
					} // END setting the next move
				}
				else
				{
					$this->set_next_turn();
				}
			} // END successful move query
			else // if( !$result )
			{
				$this->errors .= "Could not make that move: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
			}
		}//end if
		else
		{
			$this->errors .= "Invalid move!";
		}//end else

		return false;
	}//END make_move function

	/**
	 * @name set_next_turn
	 *
	 * Sets the turn of this game to the appropriate player
	**/
	function set_next_turn()
	{
		$query = "
			UPDATE
					tblgames
			SET
					currentTurn
				=
					IF(currentTurn=(SELECT MAX(orderNumber) FROM tblgameplayers WHERE gameID=$this->gameID),1,currentTurn+1)
			WHERE
					gameID=$this->gameID;";
		$mysqli = mysqli_db_connect();
		//$this->errors .= "$query<br /><br />\r";
		$result = mysqli_query($mysqli, $query );
		if( !$result )
		{
			$this->errors .= "Could not set the next turn: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
			return;
		} // END setting the next move

		// now, get the next turn
		$query = "SELECT currentTurn FROM tblgames WHERE gameID=$this->gameID;";
		$result = mysqli_query($mysqli, $query );
		if( !$result )
		{
			$this->errors .= "Could not get the current turn number: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
			return;
		} // END setting the next move
		else if( $row = mysqli_fetch_assoc( $result ) )
		{
			$this->playerTurn = $row['currentTurn'];
		}
	} // END function set_next_turn()

	/**
	 * @name set_next_player
	 * @param $playerID
	 * updates $this->playerTurn. If given $playerID = 0, that's a special
	 *    case so don't mess with it
	**/
	function set_next_player($playerID)
	{
		if($playerID != 0)
		{
			if($playerID == sizeof($this->players))
			{
				$this->playerTurn = 1;
			}//end if
			else
			{
				$this->playerTurn = $playerID + 1;
			}//end else
		}//end if
	}//END set_next_player function



	/**
	 * @name load_moves
	 *
	**/
	function load_moves()
	{
		if( !empty( $this->gameID ) )
		{
			$query = "
				SELECT
					m.moveNumber, m.orderNumber, m.moveX, m.moveY, c.colorHex, c.colorShortcut
				FROM
					tblmoves m, tblcolors c
				WHERE
					m.gameID='$this->gameID' AND m.colorID=c.colorID";
			$mysqli = mysqli_db_connect();
			$result = mysqli_query($mysqli, $query );
			if( $result )
			{
                $moveNumber = 0;
				while( $row = mysqli_fetch_assoc( $result ) )
				{
					$this->board->add_move( $row );
                    $moveNumber++;
				} // END while loop for getting moves
				$this->moveNumber = $moveNumber;
			} // END if for valid query result
		} // END valid game ID
	} // END load_moves()


	/**
	 * @name add_player
	 * @param player_id
	 * @param color_id
	 *
	 * adds a player to the current game
	 *
	 * Inserts into tblgameplayers the gameID, playerID, and colorID;
	 *	orderNumber is auto-generated
	 *
	 * Affects MySQL table:
	 * tblgameplayers
	**/
	function add_player( $playerID, $colorID )
	{
		if( ($boardID=$this->board->boardID) &&
			($playerID=intval($playerID)) &&
			($colorID=intval($colorID)))
		{
			$query = "INSERT INTO tblgameplayers
				(gameID, playerID, colorID)
			VALUES
				($this->gameID, $playerID, $colorID);";
			// save into the database
			$mysqli = mysqli_db_connect();
			$result = mysqli_query($mysqli, $query );
			if( !$result )
			{
				$this->errors .= "Could not add this player to the game: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
			} // add to the array of users for this game
			else
			{
				$orderNumber = mysqli_insert_id($mysqli);
				$this->players[$orderNumber] = array(
					"playerID"		=> $playerID,
					"colorID"		=> $colorID,
					"orderNumber"	=> $orderNumber,
				);
			} // END adding this user to this game's member list variable
		} // END IF for valid board and player IDs
	} // END add_player


	/**
	 * @name verify_move
	 * @param side
	 * @param channel
	 * @return boolean indicating if move is valid
	 *
	 * verifies that the move is ok
	**/
	function verify_move( $xCoord, $yCoord, $playerID )
	{
		$result = 1;
		//MAKE SURE IT'S THIS PLAYER'S TURN
		if( !$this->check_for_turn( $playerID ) )
		{
			$this->errors .= "Cannot make a move; it's not your turn!<br /><br />\r";
			return false;
		}
		//MAKE SURE MOVE ISN'T OFF THE BOARD
		$result &= (($xCoord >= 0) && ($xCoord < $this->board->xSize));
		$result &= (($yCoord >= 0) && ($yCoord < $this->board->ySize));
		return $result;

	}//END verify_move function

	/**
	 * @name check_for_turn
	 * @param player
	 * @return boolean indicating if it is the specified player's turn
	 *
	 * checks to see if the specified player is due to make a move
	**/
	function check_for_turn( $playerID )
	{
		$ret = 0;
		$query = "
			SELECT
				currentTurn
			FROM
				tblgames
			WHERE
				gameID=$this->gameID;";
		$mysqli = mysqli_db_connect();
		//echo "for $playerID: $query<br />\r";
		$result = mysqli_query($mysqli, $query );
		if( $result )
		{
            $found = false;
			while( $row = mysqli_fetch_assoc( $result ) )
			{
                $found = true;
				$turn = $row['currentTurn'];
				//$this->my_var_dump( $this->players );
				if( $this->players[$turn]['playerID'] == $playerID )
				{
					$ret = 1;
				} // END checking the game status
			} // END looking for the current turn info
			if(!$found)
			{	// no game found
				$this->errors .= "Game turn information could not be loaded - the game was not found in the database.<br /><br />\r";
			} // END if no moves yet
		} // END successful query
		else
		{
			$this->errors .= "Could get turn information: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
		}
		return $ret;
	}//END check_for_turn function


	/**
	 * @name translate_move
	 * @param side
	 * @param channel
	 * @return array(x,y) or false if there was a problem
	 *
	 * Uses the board's obstacle array and side, channel parameters to
	 *    translate the side,channel coordinates into x,y coordinates.
	 *    (0,0) is the upper left square
	**/
	function translate_move( $side, $channel)
	{
		$xCoord = 0;
		$yCoord = 0;
		$result = null;

		//from the left
		if($side == $this->board->side_codes["left"])
		{
			//make sure channel is within x size of board
			if($channel <= $this->board->ySize)
			{
				$yCoord = $channel;
				//are there any obstacles in this row?
				if( !empty( $this->board->row_obs[$channel] ) )
				{
					$xCoord = min($this->board->row_obs[$channel]) - 1;
				}//end if
				else
				{
					//if not, go all the way over!
					$xCoord = $this->board->xSize - 1;
				}
			}//end if
			else
			{
				return false;
			}//end else
		}//end if

		//from the right
		if($side == $this->board->side_codes["right"])
		{
			//make sure channel is within y size of board
			if($channel <= $this->board->ySize)
			{
				$yCoord = $channel;
				//are there any obstacles in this row?
				if( !empty( $this->board->row_obs[$channel] ) )
				{
					$xCoord = max($this->board->row_obs[$channel]) + 1;
				}//end if
				else
				{
					//if not, go all the way over!
					$xCoord = 0;
				}
			}//end if
			else
			{
				return false;
			}//end else
		}//end if

		//from the top
		if($side == $this->board->side_codes["top"])
		{
			//make sure channel is within x size of board
			if($channel <= $this->board->xSize)
			{
				$xCoord = $channel;
				//are there any obstacles in this row?
				if( !empty( $this->board->col_obs[$channel] ) )
				{
					$yCoord = min($this->board->col_obs[$channel]) - 1;
				}//end if
				else
				{
					//if not, go all the way over!
					$yCoord = $this->board->ySize - 1;
				}
			}//end if
			else
			{
				return false;
			}//end else
		}//end if

		//from the bottom
		if($side == $this->board->side_codes["bottom"])
		{
			//make sure channel is within x size of board
			if($channel <= $this->board->xSize)
			{
				$xCoord = $channel;
				//are there any obstacles in this row?
				if( !empty( $this->board->col_obs[$channel] ) )
				{
					$yCoord = max($this->board->col_obs[$channel]) + 1;
				}//end if
				else
				{
					//if not, go all the way over!
					$yCoord = 0;
				}
			}//end if
			else
			{
				return false;
			}//end else
		}//end if

		return array("x" => $xCoord, "y" => $yCoord);
		//*/
	}//END translate_move function





	/**
	 * @name print_board
	 * @param template
	 * @param playerID
	 * @param gameID
	 *
	 * prints the board using the supplied template
	**/
	function print_board( $template, $playerID, $gameID )
	{
		$turn = $this->playerTurn;
		if( $this->gameStatus > 1 )
		{
			$turn = 0;
		}
		if( !empty( $this->board ) )
		{
			$this->board->print_board(
				$template,
				$playerID,
				$gameID,
				$this->players,
				$turn );
		}
	}


	/**
	 * @name get_errors
	 *
	 * gets errors generated during this session
	**/
	function get_errors()
	{
		return ($this->errors . $this->board->errors);
	}

	/**
	 * @name get_info
	 *
	 * returns game info useful for sharing and returning to this game
	**/
	function get_info()
	{
		$info = $this->info;
		$urls = "";


		$mysqli = mysqli_db_connect();
		foreach( $this->players as $player )
		{
			//$urls .= "<a href=\"index.php?game=".$this->gameID."&player=$player[playerID]\">Player $player[orderNumber]</a><br />\r";

			$query = "SELECT name
			  FROM tblplayers
			  WHERE playerID=".$player['playerID'];
			$result = mysqli_query($mysqli, $query );
			if( $result )
			{
				if( $row = mysqli_fetch_assoc( $result ) )
				{
					$playerNames[$player['playerID']] = $row['name'];
				}//end if
				else
				{	// no game found
					$this->errors .= "Player name could not be found.<br /><br />\r";
				}//end else
			}//end if
			else
			{
				$this->errors .= "Could not get player name information: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
			}//end else

			$urls .= "<a href=\"index.php?game=".$this->gameID."&player=$player[playerID]\">Player: ".$playerNames[$player['playerID']]."</a><br />\r";

		}//end foreach



		if( intval($this->gameStatus) > 1 )
		{
			//$info .= "Game over! The game was won by Player ".$this->players[$this->playerTurn]['playerID']."<br />\r";
			$info .= "Game over! The game was won by ".$playerNames[$this->players[$this->playerTurn]['playerID']]." <br />\r";
		}//end if

		$info .= $urls;

		return $info;
	}



	/**
	 *
	 *
	 * @param		$var		the $_GET variable handle
	 * @access		private
	**/
	function my_var_dump( $var )
	{
		echo "<pre>";
		var_dump($var);
		echo "</pre>\r";
	}
}
?>
