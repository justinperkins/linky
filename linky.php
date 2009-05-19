<?php
// depends on spyc 0.4.1 yaml library
// http://code.google.com/p/spyc/
include('./spyc/spyc.php');

class Linky{
  public $document, $info, $title, $description, $items;
  function Linky($path){
    $this->document = Spyc::YAMLLoad($path);
    $this->info = $this->document['info'];
    $this->title = $this->info['title'];
    $this->description = $this->info['description'];
    $keys = array_keys($this->document);
    $this->items = $this->document['items'];
  }
}
?>