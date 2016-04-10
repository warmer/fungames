<?php

if(!(empty($_POST['xsize']) || empty($_POST['ysize']) || empty($_POST['board_str'])))
{
	$xSize = $_POST['xsize'];
	$ySize = $_POST['ysize'];
	$board_str = $_POST['board_str'];
}//end if

/*
             B            rB  BB  B  B    B          B    B 
$board_str = "             B            rB  BB  B  B    B          B    B ";
$xSize = 10;
$ySize = 10;
*/

$myb = str_replace(" ","+",$board_str);

echo "<pre>";

//echo $board_str."\n";
//echo $myb."\n";

for($row = 0; $row < $ySize; $row++)
{
	for($col = 0; $col < $xSize; $col++)
	{
		echo substr($myb,($row*$xSize)+$col,1);
	}//end for
	echo "\n";
}//end for

echo "</pre>";



echo "<FORM action=\"board_sim.php\" method=\"post\">\n";
echo "    <P>\n";
echo "    <LABEL for=\"xSize\">X Size: </LABEL>\n";
echo "              <INPUT type=\"text\" value=\"10\" name=xsize><BR>\n";
echo "    <LABEL for=\"ySize\">Y Size: </LABEL>\n";
echo "              <INPUT type=\"text\" value=\"10\" name=ysize><BR>\n";
echo "    <LABEL for=\"board_str\">Board String: </LABEL>\n";
echo "              <INPUT type=\"text\" name=board_str><BR>\n";
echo "    <INPUT type=\"submit\" value=\"View\">\n";
echo "    </P>\n";
echo "</FORM>\n";





?>