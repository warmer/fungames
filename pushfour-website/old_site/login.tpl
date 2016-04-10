
<h2>{WELCOME_MESSAGE}</h2>

<!-- BEGIN error -->
<pre>
{error.ERROR}
</pre>
<!-- END error -->

<form action="login.php?" method="POST">
<table>
<tr>
	<td>Username:</td>
	<td><input name="username" id="username" type="textbox" size="20" maxsize="32" id= /></td>
</tr>
<tr>
	<td>Password:</td>
	<td><input name="password" id="password" type="password" size="20" maxsize="32" /></td>
</tr>
<tr>
	<td colspan="2" style="text-align: center;">
		<input type="submit" value="Log in" />
		<input type="reset" value="Clear form" />
	</td>
</tr>
</table>
</form>

