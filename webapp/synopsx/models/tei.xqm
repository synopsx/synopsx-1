xquery version "3.0" ;
module namespace synopsx.models.tei = 'synopsx.models.tei';
(:~
 : This module is for TEI models
 : @version 0.2 (Constantia edition)
 : @date 2014-11-10 
 : @author synopsx team
 :
 : This file is part of SynopsX.
 : created by AHN team (http://ahn.ens-lyon.fr)
 :
 : SynopsX is free software: you can redistribute it and/or modify
 : it under the terms of the GNU General Public License as published by
 : the Free Software Foundation, either version 3 of the License, or
 : (at your option) any later version.
 :
 : SynopsX is distributed in the hope that it will be useful,
 : but WITHOUT ANY WARRANTY; without even the implied warranty of
 : MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 : See the GNU General Public License for more details.
 : You should have received a copy of the GNU General Public License along 
 : with SynopsX. If not, see <http://www.gnu.org/licenses/>
 :
 :)

import module namespace G = "synopsx.globals" at '../globals.xqm'; (: import globals variables :)

declare default function namespace 'synopsx.models.tei'; (: This is the default namespace:)
declare namespace tei = 'http://www.tei-c.org/ns/1.0'; (: Add namespaces :)
 


(:~
 : This function return the corpus title
 :)
declare function title() as element(){ 
  (db:open($G:DBNAME)//tei:titleStmt/tei:title)[1]
}; 
 
(:~
 : This function return a titles list
 :)
declare function listItems() as element()* { 
  db:open($G:DBNAME)//tei:titleStmt/tei:title
};

(:~
 : This function creates a map of two maps : one for metadata, one for content data
 :)
declare function listCorpus() {
  let $corpus := db:open($G:DBNAME) (: openning the database:)
  let $meta as map(*) := {
    'title' : 'Liste des corpus' (: title page:)
    }
  let $content as map(*) := map:merge(
    for $item in $corpus//tei:teiCorpus/tei:teiHeader (: every teiHeader is add to the map with arbitrary key and the result of  corpusHeader() function apply to this teiHeader:)
    return  map:entry(fn:generate-id($item), corpusHeader($item))
    )
  return  map{
    'meta'       : $meta,
    'content'    : $content
  }
};





(:~
 : This function creates a map for a corpus item with teiHeader 
 :
 : @param $item a corpus item
 : @return a map with content for each item
 : @rmq subdivised with let to construct complex queries (EC2014-11-10)
 :)
declare function corpusHeader($item as element()) {
  let $title as element()* := (
    $item//tei:titleStmt/tei:title
    )[1]
  let $date as element()* := (
    $item//tei:teiHeader//tei:date
    )[1]
  let $author  as element()* := (
    $item//tei:titleStmt/tei:author
    )[1]
  return map {
    'title'      : $title/text() ,
    'date'       : $date/text() ,
    'principal'  : $author/text()
  }
};







(:~
 : this function creates a map of two maps : one for metadata, one for content data
 :)
declare function synopsx.models.tei:listTexts() {
  let $corpus := db:open($G:DBNAME)
  let $meta as map(*) := {'title' : 'Liste des textes'}
  let $content as map(*) :=  map:merge(
    for $item in $corpus//tei:TEI/tei:teiHeader 
      
      return  map:entry(fn:generate-id($item), teiHeader($item))
    )
  return  map{
    'meta' : $meta,
    'content' : $content
  }
};

(:~
 : this function creates a map for a corpus item
 :)
declare function teiHeader($teiHeader) as map(*) {
 map {
    'title' : ($teiHeader//tei:titleStmt/*:title/text()),
    'date' : ($teiHeader//tei:date/text()),
    'author' : ($teiHeader//tei:author/text())
  }
};


(:~
 : this function creates a map of two maps : one for metadata, one for content data
 :)
declare function synopsx.models.tei:listMentioned() {
  let $corpus := db:open($G:DBNAME)
  let $meta as map(*) := {'title' : 'Liste des autonymes'}
  let $content as map(*) :=  map:merge(
    for $item in $corpus//tei:mentioned 
      
      return  map:entry(fn:generate-id($item), mentioned($item))
    )
  return  map{
    'meta' : $meta,
    'content' : $content
  }
};

(:~
 : this function creates a map for a corpus item
 :)
declare function mentioned($item) as map(*) {
 map {
    'lang' : fn:string($item/@*:lang),
    'term' : $item/text()
  }
};