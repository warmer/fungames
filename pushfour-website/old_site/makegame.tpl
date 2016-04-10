<div class="main_area">
<h2>Choose your options:</h2>

<!-- BEGIN error -->
<pre>
{error.ERROR}
</pre>
<!-- END error -->

<form action="makegame.php?" method="POST">
<table>
<tr>
	<td class="reqd">Height (4-15):</td>
	<td class="reqd"><input name="ysize" id="ysize" value="{BOARD_YSIZE}" type="textbox" size="5" maxsize="2" /></td>
</tr>
<tr>
	<td class="reqd">Width (4-15):</td>
	<td class="reqd"><input name="xsize" id="xsize" value="{BOARD_XSIZE}" type="textbox" size="5" maxsize="2" /></td>
</tr>
<tr>
	<td class="reqd"># of obstacles:</td>
	<td class="reqd"><input name="numObs" id="numObs" value="{BOARD_NUMOBS}" type="textbox" size="5" maxsize="2" /></td>
</tr>
<!-- BEGIN player_selection -->
<tr>
	<td class="reqd">Player {player_selection.PLAYER_NUM}:</td>
	<td class="reqd">
		<select id="player_{player_selection.PLAYER_NUM}" NAME="player_{player_selection.PLAYER_NUM}">
		<!-- BEGIN option -->
			<option {player_selection.option.SELECTED} value="{player_selection.option.VALUE}">{player_selection.option.TEXT}</option>
		<!-- END option -->
		</select>
	</td>
</tr>
<!-- END player_selection -->
<tr>
	<td colspan="2" style="text-align: center;">
		<input name="pushbutton" id="pushbutton" type="submit" value="Play!" />
		<input type="reset" value="Clear form" />
	</td>
</tr>
</table>
</form>

</div>
