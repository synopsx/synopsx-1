xquery version '3.0' ;
module namespace synopsx.mappings.htmlWrapping = 'synopsx.mappings.htmlWrapping' ;

(:~
 : This module is an HTML mapping for templating
 :
 : @version 2.0 (Constantia edition)
 : @since 2014-11-10 
 : @author synopsx's team
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
 : with SynopsX. If not, see http://www.gnu.org/licenses/
 :
 :)

import module namespace G = "synopsx.globals" at '../globals.xqm' ;
import module namespace synopsx.lib.commons = 'synopsx.lib.commons' at '../lib/commons.xqm' ; 

import module namespace synopsx.mappings.tei2html = 'synopsx.mappings.tei2html' at 'tei2html.xqm' ; 

declare namespace html = 'http://www.w3.org/1999/xhtml' ;

declare default function namespace 'synopsx.mappings.htmlWrapping' ;

(:~
 : this function wrap the content in an HTML layout
 :
 : @param $queryParams the query params defined in restxq
 : @param $data the result of the query
 : @param $outputParams the serialization params
 : @return an updated HTML document and instantiate pattern
 
 : @todo treat in the same loop @* and text() ?
 @todo add handling of outputParams (for example {class} attribute or call to an xslt)
 :)


(:~
 : this function wrap the content in an HTML layout
 :
 : @param $queryParams the query params defined in restxq
 : @param $data the result of the query
 : @param $outputParams the serialization params
 : @return an updated HTML document and instantiate pattern
 :
 :)
declare function wrapper($queryParams as map(*), $data as map(*), $outputParams as map(*)) as node()* {
  let $meta := map:get($data, 'meta')
  let $layout := synopsx.lib.commons:getLayoutPath($queryParams, map:get($outputParams, 'layout'))
  let $wrap := fn:doc($layout)
  let $regex := '\{(.*?)\}'
  return
    $wrap/* update (
      (: todo : call wrapping, rendering and injecting functions for these inc layouts too :)
      for $text in .//*[@data-url] 
            let $incOutputParams := map:put($outputParams, 'layout', $text/@data-url || '.xhtml')
            let $inc :=  wrapper($queryParams, $data, $incOutputParams)
            return replace node $text with $inc,
      (: keys :)      
      for $text in .//@*
        where fn:matches($text, $regex)
        return replace value of node $text with replaceOrLeave($text, $meta),
      for $text in .//text()
        where fn:matches($text, $regex)
        let $key := fn:replace($text, '\{|\}', '')       
        return if ($key = 'content') 
          then replace node $text with pattern($queryParams, $data, $outputParams)
          else 
           let $value := map:get($meta, $key)
           return if ($value instance of node()* and  fn:not(fn:empty($value))) 
           then replace node $text with render($queryParams, $outputParams, $value)
           else replace node $text with replaceOrDelete($text, $meta)      
     (: inc :)
    
      )
};

(:~
 : this function iterates the pattern template with contents
 :
 : @param $queryParams the query params defined in restxq
 : @param $data the result of the query to dispacth
 : @param $outputParams the serialization params
 : @return instantiate the pattern with $data
 :
 : @bug default for sorting
 :)
declare function pattern($queryParams as map(*), $data as map(*), $outputParams as map(*)) as node()* {
 let $sorting := if (map:get($queryParams, 'sorting')) 
    then map:get($queryParams, 'sorting') 
    else ''
  let $order := map:get($queryParams, 'order')
  let $contents := map:get($data, 'content')
  let $pattern := synopsx.lib.commons:getLayoutPath($queryParams, map:get($outputParams, 'pattern'))
  for $content in $contents
  order by (: @see http://jaketrent.com/post/xquery-dynamic-order/ :)
    if ($order = 'descending') then map:get($content, $sorting) else () ascending,
    if ($order = 'descending') then () else map:get($content, $sorting) descending
  let $regex := '\{(.*?)\}'
  return
    fn:doc($pattern)/* update (
       for $text in .//@*
        where fn:matches($text, $regex)
        return replace value of node $text with replaceOrLeave($text, $content),
      for $text in .//text()
        where fn:matches($text, $regex)
        let $key := fn:replace($text, '\{|\}', '')
        let $value := map:get($content, $key)
        return if ($value instance of node()* and fn:not(fn:empty($value))) 
          then replace node $text with render($queryParams, $outputParams, $value)
          else replace node $text with replaceOrDelete($text, $content)
      )
};

(:~
 : this function update the text with input content
 : it does not delete the non matching parts of the string (url etc.)
 :
 : @param $text the text node to process
 : @param $input the content to dispatch
 : @return an updated text
 :
 :)
declare function replaceOrLeave($text as xs:string, $input as map(*)) as xs:string {
  let $tokens := fn:tokenize($text, '\{|\}')
  let $updated := fn:string-join( 
    for $token in $tokens
    let $value := map:get($input, $token)
    return if (fn:empty($value)) 
      then $token (: leave :)
      else $value
    )
  return $updated
};

(:~
 : this function update the text with input content
 : it deletes the non matching parts of the string (unrelevant keys in body, etc.)
 : @param $text the text node to process
 : @param $input the content to dispatch
 : @return an updated text
 :
 :)
declare function replaceOrDelete($text as xs:string, $input as map(*)) as xs:string {
  let $tokens := fn:tokenize($text, '\{|\}')
  let $updated := fn:string-join( 
    for $token in $tokens
    let $value := map:get($input, $token)
    return if (fn:empty($value)) 
      then () (: delete :)
      else $value
    )
  return $updated
};

(:~
 : this function dispatch the rendering based on $outpoutParams
 :
 : @param $value the content to render
 : @param $outputParams the serialization params
 : @return an html serialization
 :
 : @todo check the xslt with an xslt 1.0
 :)
declare function render($queryParams, $outputParams as map(*), $value as node()* ) as node()* {
  let $xquery := map:get($outputParams, 'xquery')
  let $xsl :=  map:get($outputParams, 'xsl')
  let $options := 'option'
  return 
    if ($xquery) 
      then synopsx.mappings.tei2html:entry($value, $options)
    else if ($xsl) 
      then for $node in $value
           return xslt:transform($node, synopsx.lib.commons:getXsltPath($queryParams, $xsl))/*
      else $value
};


(:~
 : ~:~:~:~:~:~:~:~:~
 : templating reloaded
 : ~:~:~:~:~:~:~:~:~
 :)
 
(:~
 : this function wrap the content in an HTML layout
 :
 : @param $queryParams the query params defined in restxq
 : @param $data the result of the query
 : @param $outputParams the serialization params
 : @return an updated HTML document and instantiate pattern
 :
 :)
declare function wrapperNew($queryParams as map(*), $data as map(*), $outputParams as map(*)) as node()* {
  let $meta := map:get($data, 'meta')
  let $layout := map:get($outputParams, 'layout')
  let $wrap := fn:doc(synopsx.lib.commons:getLayoutPath($queryParams, $layout))
  let $regex := '\{.+?\}'
  return
    $wrap/* update (
      for $text in .//@* | .//text()
      where fn:matches($text, $regex)
      let $key := fn:replace($text, '\{|\}', '')
      let $value := map:get($meta, $key) 
      return if ($key = 'content') 
        then replace node $text with patternNew($queryParams, $data, $outputParams)
        else serialize($queryParams, $meta, $outputParams, $text, $value )
     )
  };

(:~
 : this function iterates the pattern template with contents
 :
 : @param $queryParams the query params defined in restxq
 : @param $data the result of the query to dispacth
 : @param $outputParams the serialization params
 : @return instantiate the pattern with $data
 :
 :)
declare function patternNew($queryParams as map(*), $data as map(*), $outputParams as map(*)) as node()* {
  let $contents := map:get($data, 'content')
  let $pattern := map:get($outputParams, 'pattern')
  let $pattern := fn:doc(synopsx.lib.commons:getLayoutPath($queryParams, $pattern))
  let $regex := '\{.+?\}'
  for $content in $contents
  return
    $pattern/* update (
      for $text in .//@* | .//text()
      where fn:matches($text, $regex)
      let $key := fn:replace($text, '\{|\}', '')
      let $value := map:get($content, $key) 
      return serialize($queryParams, $content, $outputParams, $text, $value)
     )
  };

(:~
 : this function dispatch the rendering based on $outpoutParams
 :
 :) 
declare updating function serialize($queryParams, $data as map(*), $outputParams, $text, $value) {
  let $data := $data
  let $content := map:get($data, 'content')
  let $value := $value
  return 
    switch ($value)
      case ($value instance of empty-sequence()) return ()
      case ($value instance of text()) return 
        replace value of node $text with $value
      case ($value instance of node()* and fn:not(fn:empty($value))) return 
        replace value of node $text with render($queryParams, $outputParams, $value)
      default return 
        replace value of node $text with replaceOrLeave($text, $data)
  };
 