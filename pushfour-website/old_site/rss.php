<?php
echo "<?xml version=\"1.0\"?>";
$myrand = rand( 1000, 9999 );
?>
<rss version="2.0">
  <channel>
    <title>PushFour</title>
    <link>http://nodiff.net/pushfour</link>
    <description>Pushfour feed..</description>
    <ttl>1</ttl>
	
    <item>
      <title><?php echo $myrand; ?></title>
      <link>http://nodiff.net/pushfour/index.php?game=<?php echo $myrand; ?></link>
      <description>                                                                                                                                                                                                                                                                </description>
    </item>
  </channel>
</rss>

