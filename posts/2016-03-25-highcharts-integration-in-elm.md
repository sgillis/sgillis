---
title: Highcharts.js integration in Elm
---

[Highcharts.js](http://highcharts.com) is a JavaScript library to generate graphs inside the browser. It has a pretty simple API that allows you to create a wide range of different graphs. I stumbled upon this library when looking for a solution to create some graphs in [an Elm web app that I'm working on](http://truqu.com).

Highcharts documentation gives an [example](http://www.highcharts.com/docs/getting-started/your-first-chart) to create a simple bar chart. In it, you are instructed to create a `div` element, load it using `jQuery` and call the `highcharts` function on the element. So something like this

```
<div id="container"></div>

<script>
$(function () { 
    $('#container').highcharts({ ... });
});
</script>
```

The argument to `highcharts` is just a dict that contains all data and configuration options for the chart as described in their [API documentation](http://api.highcharts.com/highcharts). Easy enough.

But I want this to be integrated in [an Elm web app](truqu.com), where I can't just create a `div` element and load it in`jQuery`. This is because the app uses `elm-html`, which uses the [`virtual-dom`](https://github.com/Matt-Esch/virtual-dom) project behind the screens. This means that a virtual DOM will be created by the app, and rendered at runtime. So it's not obvious when to call the `highcharts` function on the `div` that will contain the chart, since we don't know when the HTML element will be present.

<!--more-->

While looking through the [`virtual-dom` documentation](https://github.com/Matt-Esch/virtual-dom/tree/master/docs) I stumbled upon [`hooks`](https://github.com/Matt-Esch/virtual-dom/blob/master/docs/hooks.md). According to the documentation, hooks are functions that execute after turning a virtual node into an element. That sounds useful! So I decided to try and integrate `Highcharts.js` in Elm using such a hook.

The result is the (unfinished) library found at [`sgillis/elm-highcharts`](https://github.com/sgillis/elm-highcharts). The most important function in the library is [`highchart`](https://github.com/sgillis/elm-highcharts/blob/v2.0.0/src/Highcharts.elm#L30-L32). It takes a type `Chart` and returns a `Html` element that can be integrated into any Elm app that is using `evancz/elm-html`. The definition is very simple

```elm
type alias Chart =
  { chartOptions : ChartOptions
  , tooltip : String
  , plotOptions : List PlotOptions
  , series : Series
  }

highchart : Chart -> Html
highchart =
  Native.Highcharts.highchart
```

The types `ChartOptions`, ... are just more Elm types that are just Elm versions of the dicts that are defined in the Highcharts documentation. So this function is equivalent to the `highcharts` JavaScript function that should be called when the div element is loaded with jQuery.

So what is this `Native.Highcharts.highchart` function? It's a pretty short function:

```elm
  function highchart(chart){
    var propertyList = List.fromArray(
      [ { key: "highchart-hook", value: new Hook(chart) } ]
    );
    var node =
          A3(VirtualDom.node, "highchart", propertyList, List.fromArray([]));
    return node;
  }
```

What this does is create a new `VirtualDom.node` which is exactly what the `Html` type is in Elm. We also add a single custom property, namely an instance of an object called `Hook`. This object has a method called `hook` that will be called when the `VirtualDom.node` is rendered on the page. This is exactly the `virtual-dom` hook I mentioned earlier.

The hook function receives an argument that is the newly created node, so we can load that node with jQuery and call the `highcharts` JavaScript function on that. So the hook is defined as

```
var Hook = function(chart){
    this.chart = decode(chart);
    this.highchart = undefined;
};

Hook.prototype.hook = function(node, propertyName, previousValue) {
    if(previousValue === undefined || previousValue.highchart === undefined){
        this.initialize(node, propertyName, previousValue);
    }
};

Hook.prototype.initialize = function(node, propertyName, previousValue){
    this.highchart = new Highcharts.Chart(node, {
        chart: this.chart.chartOptions,
        plotOptions: this.chart.plotOptions,
        series: this.chart.series
    });
};
```

You can see a [working example here](http://sgillis.github.io/elm-highcharts/).

This is just a very basic example of how to use `virtual-dom` hooks inside an Elm project. I hadn't read about this approach yet, so I decided to write up what I found in case it would be interesting to someone else facing a similar problem. At the moment there has also been some discussion in the `elm-dev` mailing group about what to do with native integrations. As I understood Evan is working on improving this in the to be released version of Elm (v0.17). I'm not sure what his ideas will be, but maybe it could be that it involves exposing these hooks somehow?

I'm very interested to hear from the Elm community what they think about this approach, so feel free to send me a message or leave a comment.
