<?php

include_once('functions.php');

/**
 * Board class
 *
 * contains methods for loading and creating a board, and making moves
**/

class Board
{
	var $classname = "Board";
	
	var $side_codes = array("left"=>'l', "right"=>'r', "top"=>'t', "bottom"=>'b');
	var $obstacle_code = "#";
	
	var $boardID = 0;
	
	var $xSize = 0;
	var $ySize = 0;
	var $size = 0;
	
	var $num_obstacles = 0;
	// [col][row]
	var $col_obs = array();
	// [row][col]
	var $row_obs = array();
	var $board_str = "";
	
	var $obs_colors = array();
	
	var $errors = "";
	
	/**
	 * @name Board
	 * @param xSize
	 * @param ySize
	 * @param num_obstacles
	 * 
	**/
	function Board($xSize = 0, $ySize = 0, $num_obstacles = 10)
	{
		// only continue if xSize and ySize are valid
		if( $xSize && $ySize )
		{
			$this->new_board( $xSize, $ySize, $num_obstacles );
		} // END checking of x, y sizes
	}
	
	
	function set_board_str($new_str)
	{
		$this->board_str = $new_str;		
	}//end function set_board_str
	
	
	
	/**
	 * @name new_board
	 * @param xSize
	 * @param ySize
	 * @param num_obstacles
	 * 
	**/
	function new_board($xSize = 10, $ySize = 10, $num_obstacles = 10 )
	{
		$xSize = intval( $xSize );
		$ySize = intval( $ySize );
		$size = $xSize*$ySize;
		// make the board small enough
		if( $size > 255 )
		{
			$xSize = min( $xSize, 15 );
			$ySize = min( $ySize, 15 );
			$size = $xSize*$ySize;
		}
		// make the board big enough
		else if( $size < 7 )
		{
			$xSize = max( $xSize, 4 );
			$ySize = max( $ySize, 4 );
			$size = $xSize*$ySize;
		}
		// make the board big enough
		else if( ( $xSize < 4 ) && ( $ySize < 4 ) )
		{
			if( $xSize < $ySize )
			{
				$ySize = 4;
			}
			else
			{
				$xSize = 4;
			}
			
			$size = $xSize*$ySize;
		}
		
		// Save the variables
		$this->xSize = $xSize;
		$this->ySize = $ySize;
		$this->size = $size;
		
		$num_obstacles = min( intval( $num_obstacles ), $size - 7 );
		$this->num_obstacles = $num_obstacles;
		$board_str = str_pad("", $size);
		// calculate the position of the obstacles randomly
		while( $num_obstacles > 0 )
		{
			$obs = rand( 0, $size-1 );
			if( $board_str{$obs} == ' ' )
			{
				$this->row_obs[floor($obs/$xSize)][$obs%$xSize] = $obs%$xSize;
				$this->col_obs[$obs%$xSize][floor($obs/$xSize)] = floor($obs/$xSize);
				$board_str{$obs} = $this->obstacle_code;
				$num_obstacles--;
			}
		} // END building obstacles arrays
		// save into the database
		$query = "INSERT INTO tblboards (xSize, ySize, layout)
			VALUES ('$xSize', '$ySize', '$board_str' );";
		$mysqli = mysqli_db_connect();
		$result = mysqli_query($mysqli, $query );
		if( $result )
		{
			$this->boardID = mysqli_insert_id($mysqli);
			if( empty( $this->boardID ) )
			{
				$errors .= "Unable to find the newly created board in the database.<br /><br />\r";
			}
		}
		else
		{
			$this->errors .= "Could not create a new board: MySQL Error ".mysqli_connect_errno($mysqli).": ".mysqli_connect_error()."<br /><br />\r";
		}
		$this->board_str = $board_str;
	} // END new_board
	
	/**
	 * @name load_board
	 * @param gameID existing game ID
	 * 
	**/
	function load_board($boardID = 0)
	{	// sanitize that input!
		$boardID = intval( $boardID );
		if( $boardID )
		{
			$query = "
				SELECT
					*
				FROM
					tblboards
				WHERE
					boardID='$boardID'";
			$mysqli = mysqli_db_connect();
			$result = mysqli_query($mysqli, $query );
			if( $result && ($row = mysqli_fetch_assoc( $result )) )
			{
				$this->xSize = $row['xSize'];
				$this->ySize = $row['ySize'];
				$this->size = $this->xSize*$this->ySize;
				$this->boardID = $row['boardID'];
				$this->board_str = $row['layout'];
				$this->update_obstacles();
				return true;				
			}
		}		
		return false;
	} // END load_board
	
	/**
	 * @name update_obstacles
	 *
	 * looks at the board_str string and updates the obstacles accordingly
	**/
	function update_obstacles()
	{
		$board_str = $this->board_str;
		$this->num_obstacles = 0;
		$prev = 0;
		while( ($prev = strpos( $board_str, $this->obstacle_code, $prev )) !== FALSE )
		{
			$this->add_obstacle( $prev, $this->obstacle_code);
			$prev++;
			$this->num_obstacles++;
		} // END obstacle loop
	}
	
	/**
	 * @name add_obstacle
	 * @param ind absolute offset from 1-d board array
	 * @param key the color/block type
	 * @param replace TRUE when the board_str is replaced
	 *
	 * looks at the board_str string and updates the obstacles accordingly
	**/
	function add_obstacle( $ind, $key, $replace = FALSE)
	{
		$this->row_obs[floor($ind/$this->xSize)][$ind%$this->xSize] = $ind%$this->xSize;
		$this->col_obs[$ind%$this->xSize][floor($ind/$this->xSize)] = floor($ind/$this->xSize);
		if( $replace )
		{
			$this->board_str{$ind} = $key;
		}
	}
	
	
	/**
	 * @name get_color
	 * @param key the color shortcut
	 *
	 * gets the color associated with the given shortcut
	**/
	function get_color( $key )
	{
		if( !array_key_exists( $key, $this->obs_colors ) )
		{
			$this->add_color( $key );
		}
		return $this->obs_colors[$key];
	}
	
	/**
	 * @name add_color
	 * @param key the color shortcut
	 *
	 * retrieves the color associated with the given shortcut from the
	 * database
	**/
	function add_color( $key )
	{
		$query = "SELECT colorHex FROM tblcolors WHERE colorShortcut='$key';";
		$mysqli = mysqli_db_connect();
		$result = mysqli_query($mysqli, $query );
		if( $result )
		{
			$row = mysqli_fetch_assoc( $result );
			if( $row )
			{
				$this->obs_colors[$key] = $row['colorHex'];
			} // END while loop for getting moves
			else
			{
				$this->obs_colors[$key] = "#666";
			}
		} // END if for valid query result
		else
		{
			$this->obs_colors[$key] = "#666";
		}
	}
	
	/**
	 * @name print_board
	 * @param template
	 * @param playerID
	 * @param gameID
	 * @param players
	 * @param isTurn
	 *
	 * prints the board using the supplied template
	**/
	function print_board($template, $playerID, $gameID, $players, $turn )
	{
		$cols = $this->xSize;
		$rows = $this->ySize;
		$col_obs = $this->col_obs;
		$row_obs = $this->row_obs;
		$active = ($players[$turn]['playerID'] == $playerID);
		$piece_color = $active ? $players[$turn]['colorHex'] : "#ffffff";
		// add gobal template variables
		$template->assign_vars( array(
				"ROWS"			=> $rows,
				"COLS"			=> $cols,
				"PIECE_COLOR"	=> $piece_color,
				"CLEAR_COLOR"	=> "#ffffff",
				"GAMEID"		=> $gameID,
				"PLAYERID"		=> $playerID,
				"TURN"			=> $turn,
			)
		);
		// build the top row of moves
		for( $i = 0; $i < $cols; $i++)
		{
			$tend = $rows;
			if( isset( $col_obs[$i] ) )
			{
				$tend = min( $col_obs[$i] );
			}
			$template->assign_block_vars( "top_row", array(
					"ID"	=> $i,
					"TEND"	=> $tend,
				)
			);
			if( $active )
			{
				$template->assign_block_vars( "top_row.t_js_actions", array() );
			}
		} // END top row builder
		
		/**
		 * MAIN block-building loop
		**/
		for( $i = 0; $i < $rows; $i++)
		{
			$lend = $cols;
			$rstart = 0;
			if( isset( $row_obs[$i] ) )
			{
				$lend = min( $row_obs[$i] );
				$rstart = max( $row_obs[$i] );
			}
			$template->assign_block_vars( "row", array(
					"ID"	=> "$i",
					"LEND"=> $lend,
					"RSTART"=> $rstart,
				)
			);
			if( $active )
			{
				$template->assign_block_vars( "row.r_js_actions", array() );
				$template->assign_block_vars( "row.l_js_actions", array() );
			}
			// build the columns
			for( $j = 0; $j < $cols; $j++)
			{
				$style = "";
				if( isset( $row_obs[$i][$j] ) )
				{
					$ind = $j + $i*$cols;
					$key = $this->board_str{$ind};
					$style = "background-color: ".$this->get_color( $key ).";";
				}
				$template->assign_block_vars( "row.block", array(
						"ID"	=> "$j-$i",
						"STYLE"	=> $style,
					)
				);
			} // END column builder
		} // END row builder
		
		// build the bottom row of moves
		for( $j = 0; $j < $cols; $j++)
		{
			$bstart = 0;
			if( isset( $col_obs[$j] ) )
			{
				$bstart = max( $col_obs[$j] );
			}
			$template->assign_block_vars( "bottom_row", array(
					"ID"	=> "$j",
					"BSTART"=> $bstart,
				)
			);
			if( $active )
			{
				$template->assign_block_vars( "bottom_row.b_js_actions", array() );
			}
		} // END bottom row builder
	} // END print_board
	
	
	
	/**
	 * @name verify_move
	 * @param x
	 * @param y
	 * @param playerID
	 *
	 * verifies a move
	**/
	function verify_move( $x, $y, $playerID )
	{
		
	}
	
	
	/**
	 * @name make_move
	 * @param x
	 * @param y
	 * @param playerID
	 *
	 * adds a player to the current game
	**/
	function make_move( $x, $y, $playerID )
	{
//		if( $this->verify_move( $x, $y, $playerID ) )
//		{
//			
//			
//			$this->add_obstacle( $this->xSize*$move['moveY']+$move['moveX'], $move['colorShortcut'], TRUE );
//		}
	} // END make_move
	
	
	
	/**
	 * @name add_move
	 * @param move
	 *
	 * adds a player to the current game
	**/
	function add_move( $move )
	{	// add an obstacle to the board (since you cannot move through blocks
		$this->add_obstacle( $this->xSize*$move['moveY']+$move['moveX'], $move['colorShortcut'], TRUE );
	} // END add_move
}
