<?php
    if ($handle = opendir('.')) {
        while (false !== ($entry = readdir($handle))) {
            if ($entry != "." && $entry != "..") {
            	echo $entry;
                exec('./AddObj ' . $entry);
            }
        }
        closedir($handle);
   }
?>