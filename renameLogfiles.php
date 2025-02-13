#!/usr/bin/php
<?php

$prefix = "access-clausthal-";

for ( $i = 1; $i < count($argv) ; $i++) {
    $file = $argv[$i];
    $dir = dirname($file); 
    if (! is_file($file) ) {
        echo "Error: couldn't file file".$file;
        continue;
    }
    $time = shell_exec('tail -n 1 '.$file.' | cut -d "[" -f2 | cut -d "]" -f1');

    $time = new DateTime($time);
    $date = $time->format('Y-m-d');

    $newFile=$dir."/".$prefix.$date.".log";

    echo "rename ".$file."->".$newFile."\n";
    rename ($file,$newFile);
}

?>
