<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?php
include('./linky.php');

$linky = new Linky('./linky.yml');
?>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
  	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  	<title><?php echo $linky->title; ?></title>
  	<meta name="description" value="<?php echo $linky->description; ?>" />
	  <style type="text/css">
	    *{ margin:0; padding:0; }
	    h1, h2{ display:none; }
	    ul li.entry{
	      list-style:none;
	      float:left;
	      width:100px;
	      height:100px;
	      background:transparent none no-repeat top left
	    }
	    ul li.no-link, ul li a{
	      display:block;
	      float:left;
	      width:100px;
	      height:100px;
	      text-indent:-9999px;
	    }
	    ul li.entry ul{ display:none; }
	  </style>
  </head>
  <body>
    <h1><?php echo $linky->title ?></h1>
    <h2><?php echo $linky->description ?></h2>
    <ul>
      <?php foreach ($linky->items as $i => $entry) {?>
        <li class="entry <?php if (!isset($entry['link'])) { echo 'no-link'; } ?>" style="background-image:url(<?php if (isset($entry['background_image'])) { echo $entry['background_image']; } ?>);">
          <?php if (isset($entry['link'])) { echo '<a href="' . $entry['link'] . '">'; } ?>
          <ul>
          <?php foreach (array_keys($entry) as $j => $key) { ?>
            <?php if ($entry[$key] != '') { ?>
              <li class="<?php echo $key; ?>"><?php echo $entry[$key]; ?></li>
            <?php } ?>
          <?php } ?>
          </ul>
          <?php if (isset($entry['link'])) { echo "</a>"; } ?>
        </li>
      <?php } ?>
    </ul>
  </body>
</html>